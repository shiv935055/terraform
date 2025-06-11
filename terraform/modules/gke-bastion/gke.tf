# gke.tf
resource "google_container_cluster" "primary" {
  name               = var.cluster_name
  location           = var.region
  initial_node_count = 1
  deletion_protection = false
  network            = google_compute_network.vpc_network.name
  subnetwork         = google_compute_subnetwork.subnetwork.name
  ip_allocation_policy {
    cluster_secondary_range_name  = "pods-subnet"
    services_secondary_range_name = "services-subnet"
  }
  private_cluster_config {
    enable_private_endpoint = true
    enable_private_nodes    = true
    master_ipv4_cidr_block  = var.master_ipv4_cidr_block
  }
  master_authorized_networks_config {
    cidr_blocks {
      cidr_block = var.master_ipv4_cidr_block
    }
  }
  addons_config {
    horizontal_pod_autoscaling {}
    http_load_balancing {}
    network_policy_config {}
  }
  logging_service    = "logging.googleapis.com/kubernetes"
  monitoring_service = "monitoring.googleapis.com/kubernetes"
}
resource "google_container_node_pool" "primary_nodes" {
  name       = "primary-node-pool"
  location   = "asia-south1"
  cluster    = google_container_cluster.primary.name

  initial_node_count = 1

  node_config {
    machine_type = "e2-medium"

    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]

    service_account = "default"

    metadata = {
      disable-legacy-endpoints = "true"
    }

    labels = {
      env = "prod"
    }

    tags = ["gke-node"]
  }

  management {
    auto_repair  = true
    auto_upgrade = true
  }

  autoscaling {
    min_node_count = 1
    max_node_count = 3
  }
}
