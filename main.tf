# Create VPC
resource "google_compute_network" "vpc_network" {
  name                    = var.vpc_name
  auto_create_subnetworks = false
}

# Create subnet with secondary IP ranges
resource "google_compute_subnetwork" "subnetwork" {
  name          = var.subnet_name
  ip_cidr_range = var.gke_node_cidr
  region        = var.region
  network       = google_compute_network.vpc_network.id
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

# Create private GKE cluster
resource "google_container_cluster" "private_cluster" {
  provider           = google-beta
  name               = var.cluster_name
  location           = var.zone
  initial_node_count = 1

  network    = google_compute_network.vpc_network.name
  subnetwork = google_compute_subnetwork.subnetwork.name

  networking_mode = "VPC_NATIVE"
  ip_allocation_policy {
    cluster_secondary_range_name  = "pods-subnet"
    services_secondary_range_name = "services-subnet"
  }

  private_cluster_config {
    enable_private_nodes    = true
    enable_private_endpoint = true
    master_ipv4_cidr_block  = var.master_ipv4_cidr_block
  }

  # Authorize both subnet (GKE nodes) and master network
  master_authorized_networks_config {
    cidr_blocks {
      cidr_block   = var.gke_node_cidr  # Your subnet CIDR (GKE nodes)
      display_name = "gke-nodes-access"
    }
    cidr_blocks {
      cidr_block   = var.master_ipv4_cidr_block  # Master network CIDR
      display_name = "master-network-access"
    }
  }
  node_config {
    machine_type = "e2-medium"
    tags         = ["gke-node"]
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]
  }

  depends_on = [
    google_compute_router_nat.nat
  ]
}

# Create bastion host
resource "google_compute_instance" "bastion" {
  name         = var.bastion_name
  machine_type = "e2-medium"
  zone         = var.zone

  boot_disk {
    initialize_params {
      image = "ubuntu-minimal-2204-jammy-v20240514"
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

# NEW: Allow internal communication within VPC
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
