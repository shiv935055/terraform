# provider_vars.tf
provider "google" {
  project = var.project_id
  region  = var.region
}
