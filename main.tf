# Global IP Address
resource "google_compute_global_address" "lb_ip" {
  name = "lb-ip-address"
}

# SSL Certificate
resource "google_compute_managed_ssl_certificate" "domain_cert" {
  name = "plutos-one-ssl-cert"
  managed {
    domains = var.domains
  }
}

# Health Checks
resource "google_compute_health_check" "gke_health_checks" {
  for_each = var.gke_services

  name                = "gke-health-check-${each.key}"
  timeout_sec         = 5
  check_interval_sec  = 10

  http_health_check {
    port         = each.value.health_check_port
    request_path = each.value.health_check_path
  }
}

# GKE Backend Services
resource "google_compute_backend_service" "gke_services" {
  for_each = var.gke_services

  name                  = "backend-gke-${each.key}"
  protocol              = "HTTP"
  port_name             = "http"
  load_balancing_scheme = "EXTERNAL_MANAGED"
  timeout_sec           = 30
  health_checks         = [google_compute_health_check.gke_health_checks[each.key].id]

  dynamic "backend" {
    for_each = each.value.negs
    content {
      group          = "projects/${var.project_id}/zones/${backend.value.zone}/networkEndpointGroups/${backend.value.name}"
      balancing_mode = "RATE"
      max_rate_per_endpoint = 100
      capacity_scaler = 1.0
    }
  }
}

# Cloud Run Configuration
resource "google_compute_region_network_endpoint_group" "cloud_run_neg" {
  name                  = "cr-neg-${var.cloud_run_service}"
  network_endpoint_type = "SERVERLESS"
  region                = var.region
  cloud_run {
    service = var.cloud_run_service
  }
}

resource "google_compute_backend_service" "cloud_run_backend" {
  name                  = "backend-cr-${var.cloud_run_service}"
  protocol              = "HTTP"
  port_name             = "http"
  load_balancing_scheme = "EXTERNAL_MANAGED"
  timeout_sec           = 30

  backend {
    group           = google_compute_region_network_endpoint_group.cloud_run_neg.id
  }
}

# URL Map & Routing
resource "google_compute_url_map" "main" {
  name            = "main-url-map"
  default_service = google_compute_backend_service.gke_services["service1"].id

  # Service domains
  dynamic "host_rule" {
    for_each = var.gke_services
    content {
      hosts        = [host_rule.value.domain]
      path_matcher = "service-${host_rule.key}"
    }
  }

  # Cloud Run domain
  host_rule {
    hosts        = [var.cloud_run_domain]
    path_matcher = "cloud-run"
  }

  # Path matchers for GKE services
  dynamic "path_matcher" {
    for_each = var.gke_services
    content {
      name            = "service-${path_matcher.key}"
      default_service = google_compute_backend_service.gke_services[path_matcher.key].id
    }
  }

  # Path matcher for Cloud Run
  path_matcher {
    name            = "cloud-run"
    default_service = google_compute_backend_service.cloud_run_backend.id
  }
}

# Frontend Configuration
resource "google_compute_target_https_proxy" "main" {
  name             = "main-https-proxy"
  url_map          = google_compute_url_map.main.id
  ssl_certificates = [google_compute_managed_ssl_certificate.domain_cert.id]
}

resource "google_compute_global_forwarding_rule" "https" {
  name                  = "https-forwarding-rule"
  target                = google_compute_target_https_proxy.main.id
  port_range            = "443"
  ip_protocol           = "TCP"
  load_balancing_scheme = "EXTERNAL_MANAGED"
  ip_address            = google_compute_global_address.lb_ip.address
}

# Firewall Rule
resource "google_compute_firewall" "health_check" {
  name    = "allow-health-checks"
  network = var.network

  allow {
    protocol = "tcp"
    ports    = [for s in var.gke_services : s.health_check_port]
  }

  source_ranges = ["130.211.0.0/22", "35.191.0.0/16"]
  target_tags   = var.target_tags
}
