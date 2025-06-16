# Create VPC
resource "google_compute_network" "vpc_network" {
  name                    = var.vpc_name
  auto_create_subnetworks = false
}

# Create subnet with secondary IP ranges and enable Private Google Access
resource "google_compute_subnetwork" "subnetwork" {
  name                     = var.subnet_name
  ip_cidr_range            = var.gke_node_cidr
  region                   = var.region
  network                  = google_compute_network.vpc_network.id
  private_ip_google_access = true

  secondary_ip_range {
    range_name    = "pods-subnet"
    ip_cidr_range = var.pods_cidr
  }
  secondary_ip_range {
    range_name    = "services-subnet"
    ip_cidr_range = var.svc_cidr
  }
}

# Create static IP for NAT
resource "google_compute_address" "nat_static_ip" {
  name   = "nat-static-ip"
  region = var.region
}

# Create Cloud Router
resource "google_compute_router" "router" {
  name    = "cloud-router"
  region  = var.region
  network = google_compute_network.vpc_network.id
}

# Create Cloud NAT with static IP
resource "google_compute_router_nat" "nat" {
  name                               = "cloud-nat"
  router                             = google_compute_router.router.name
  region                             = var.region
  nat_ip_allocate_option             = "MANUAL_ONLY"
  nat_ips                            = [google_compute_address.nat_static_ip.self_link]
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
}

# Create regional private GKE cluster with reduced resources
resource "google_container_cluster" "private_cluster" {
  provider           = google-beta
  name               = var.cluster_name
  location           = var.region

  network    = google_compute_network.vpc_network.name
  subnetwork = google_compute_subnetwork.subnetwork.name

  networking_mode = "VPC_NATIVE"
  ip_allocation_policy {
    cluster_secondary_range_name  = "pods-subnet"
    services_secondary_range_name = "services-subnet"
  }

  # Using single zone to reduce resource usage temporarily
  node_locations = [var.zone]

  # Reduced autoscaling configuration
  cluster_autoscaling {
    enabled = true
    resource_limits {
      resource_type = "cpu"
      minimum      = 1
      maximum      = 4
    }
    resource_limits {
      resource_type = "memory"
      minimum      = 2
      maximum      = 16
    }
  }

  # Node pool with reduced resources
  node_pool {
    name               = "default-pool"
    initial_node_count = 1

    management {
      auto_repair  = true
      auto_upgrade = false
    }

    upgrade_settings {
      max_surge       = 1
      max_unavailable = 0
    }

    node_config {
      machine_type = "e2-small"
      disk_size_gb = 50
      disk_type    = "pd-standard"
      tags         = ["gke-node"]
      oauth_scopes = [
        "https://www.googleapis.com/auth/cloud-platform"
      ]
    }
  }

  private_cluster_config {
    enable_private_nodes    = true
    enable_private_endpoint = true
    master_ipv4_cidr_block  = var.master_ipv4_cidr_block
    master_global_access_config {
      enabled = true
    }
  }

  master_authorized_networks_config {
    cidr_blocks {
      cidr_block   = var.gke_node_cidr
      display_name = "gke-nodes-access"
    }
    cidr_blocks {
      cidr_block   = var.master_ipv4_cidr_block
      display_name = "master-network-access"
    }
    gcp_public_cidrs_access_enabled = false
  }

  depends_on = [
    google_compute_router_nat.nat
  ]
}

# Create bastion host with reduced resources
resource "google_compute_instance" "bastion" {
  name         = var.bastion_name
  machine_type = "e2-small"
  zone         = var.zone

  boot_disk {
    initialize_params {
      image = "ubuntu-minimal-2204-jammy-v20240514"
      size  = 20
      type  = "pd-standard"
    }
  }

  network_interface {
    network    = google_compute_network.vpc_network.id
    subnetwork = google_compute_subnetwork.subnetwork.id

    access_config {
      // Ephemeral public IP
    }
  }

  metadata_startup_script = <<-EOF
    #!/bin/bash
    apt-get update
    apt-get install -y kubectl google-cloud-sdk-gke-gcloud-auth-plugin
    bash <(curl -fsS https://packages.openvpn.net/as/install.sh) --yes
    sudo /usr/local/openvpn_as/scripts/sacli --user openvpn --new_pass 'redhat@123' SetLocalPassword
  EOF

  tags = ["bastion"]
}

# Create firewall rule for bastion SSH access
resource "google_compute_firewall" "bastion_ssh" {
  name    = "allow-bastion-ssh"
  network = google_compute_network.vpc_network.name

  allow {
    protocol = "tcp"
    ports    = ["22", "943"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["bastion"]
}

# Allow internal communication within VPC
resource "google_compute_firewall" "internal_communication" {
  name    = "allow-internal-traffic"
  network = google_compute_network.vpc_network.name

  allow {
    protocol = "icmp"
  }

  allow {
    protocol = "tcp"
    ports    = ["0-65535"]
  }

  allow {
    protocol = "udp"
    ports    = ["0-65535"]
  }

  source_ranges = [var.gke_node_cidr, var.master_ipv4_cidr_block]
  target_tags   = ["gke-node", "bastion"]
}

# Create snat server with reduced resources
resource "google_compute_instance" "snat" {
  name         = var.snat_name
  machine_type = "e2-small"
  zone         = var.zone

  boot_disk {
    initialize_params {
      image = "ubuntu-minimal-2204-jammy-v20240514"
      size  = 20
      type  = "pd-standard"
    }
  }

  network_interface {
    network    = google_compute_network.vpc_network.id
    subnetwork = google_compute_subnetwork.subnetwork.id
  }

  metadata_startup_script = <<-EOF
    #!/bin/bash
    apt-get update
    apt-get install -y kubectl google-cloud-sdk-gke-gcloud-auth-plugin
    apt-get install -y haproxy

    systemctl enable haproxy
    systemctl restart haproxy

    mkdir -p /etc/haproxy/certs/if51-prod-23may.plutos.one

    sudo bash -c 'cat <<'"'"'EOCFG'"'"' > /etc/haproxy/haproxy.cfg
global
    log /dev/log local0
    maxconn 5000
    daemon
    tune.ssl.default-dh-param 2048

defaults
    log global
    mode http
    option httplog
    option dontlognull
    option http-server-close
    option forwardfor
    retries 3
    timeout connect 5s
    timeout client  60s
    timeout server  60s

listen stats
    bind :8404
    mode http
    stats enable
    stats hide-version
    stats uri /haproxy?stats
    stats refresh 5s
    stats auth lordofring:idfcpass

frontend http_in
    bind :80
    acl host_uat hdr(host) -i if51-prod-23may.plutos.one
    default_backend npcibackends

backend npcibackends
    balance roundrobin
    option httpchk GET /api-admin/ping
    http-check send hdr Host npcibackend.local
    default-server inter 5s fall 2 rise 2
    server npci_siteA 192.168.116.134:443 ssl check verify none
    server npci_siteB 192.168.171.64:443 ssl check verify none

frontend https_in
    bind :443 ssl crt /etc/haproxy/certs/if51-prod-23may.plutos.one/combined.pem
    default_backend gkebackend

backend gkebackend
    balance roundrobin
    server gke_node1 192.168.10.52:80 check
EOCFG'

    systemctl restart haproxy
  EOF

  tags = ["snat"]
}

# Create database server with reduced resources
resource "google_compute_instance" "database" {
  name         = var.database_name
  machine_type = "e2-small"
  zone         = var.zone

  boot_disk {
    initialize_params {
      image = "ubuntu-minimal-2204-jammy-v20240514"
      size  = 30
      type  = "pd-standard"
    }
  }

  network_interface {
    network    = google_compute_network.vpc_network.id
    subnetwork = google_compute_subnetwork.subnetwork.id
  }

  metadata_startup_script = <<-EOF
    #!/bin/bash
    set -e

    apt-get update
    apt-get install -y gnupg wget apt-transport-https ca-certificates software-properties-common

    wget -qO- https://pgp.mongodb.com/server-7.0.asc | gpg --dearmor | tee /usr/share/keyrings/mongodb-server-7.0.gpg >/dev/null
    echo "deb [ arch=amd64,arm64 signed-by=/usr/share/keyrings/mongodb-server-7.0.gpg ] https://repo.mongodb.org/apt/ubuntu \$(lsb_release -cs)/mongodb-org/7.0 multiverse" | tee /etc/apt/sources.list.d/mongodb-org-7.0.list

    apt-get update -y
    apt-get install -y mongodb-org

    sed -i 's/bindIp: 127.0.0.1/bindIp: 0.0.0.0/' /etc/mongod.conf

    systemctl enable --now mongod
    systemctl restart mongod
  EOF

  tags = ["database"]
}

# Create firewall rule for database access
resource "google_compute_firewall" "database_access" {
  name    = "allow-database-access"
  network = google_compute_network.vpc_network.name

  allow {
    protocol = "tcp"
    ports    = ["22", "27017"]
  }

  source_ranges = [
    var.gke_node_cidr,
    var.master_ipv4_cidr_block
  ]

  target_tags = ["database"]
}
