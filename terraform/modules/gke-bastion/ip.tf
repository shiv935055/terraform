# ip.tf
resource "google_compute_address" "global_ip" {
  name         = var.global_ip_name
  address_type = "EXTERNAL"
  region       = var.region
}
