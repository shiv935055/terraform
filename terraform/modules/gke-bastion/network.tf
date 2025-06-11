# network.tf
resource "google_compute_network" "vpc_network" {
  name                    = var.vpc_name
  auto_create_subnetworks = false
  depends_on = [null_resource.prep]
}
resource "google_compute_subnetwork" "subnetwork" {
  name          = var.subnet_name
  ip_cidr_range = var.gke_node_cidr
  region        = var.region
  network       = google_compute_network.vpc_network.id
  
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
