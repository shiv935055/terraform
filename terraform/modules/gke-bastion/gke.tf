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
