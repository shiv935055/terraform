output "load_balancer_ip" {
  description = "IP address of the load balancer"
  value       = google_compute_global_address.lb_ip.address
}

output "domains" {
  description = "List of domains to configure in GoDaddy"
  value       = var.domains
}

# Fixed SSL certificate status output
#output "ssl_certificate_status" {
#  description = "Status of the SSL certificate"
#  value       = google_compute_managed_ssl_certificate.domain_cert.status
#}

output "gcp_health_check_ips" {
  description = "IP ranges for GCP health checks"
  value       = ["130.211.0.0/22", "35.191.0.0/16"]
}

output "service_domains" {
  description = "Mapping of service names to domains"
  value = {
    for key, service in var.gke_services : key => service.domain
  }
}
