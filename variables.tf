variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "region" {
  description = "GCP Region"
  type        = string
}

variable "domains" {
  description = "List of domains for SSL certificate"
  type        = list(string)
}

variable "cloud_run_service" {
  description = "Cloud Run service name"
  type        = string
}

variable "gke_services" {
  description = "GKE service configurations"
  type = map(object({
    health_check_port = number
    health_check_path = string
    domain            = string
    negs = list(object({
      zone = string
      name = string
    }))
  }))
}

variable "cloud_run_domain" {
  description = "Domain for Cloud Run service"
  type        = string
}

variable "network" {
  description = "VPC network name"
  type        = string
}

variable "target_tags" {
  description = "Target tags for firewall rules"
  type        = list(string)
}
