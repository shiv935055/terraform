terraform {
  required_version = ">= 1.0.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 4.0"
    }
  }
}

provider "google" {
  project = var.project_id
  credentials = file("/root/shiv-test-457317-3c044c3cb6f0.json")
  region  = var.region
}

provider "google-beta" {
  project = var.project_id
  credentials = file("/root/shiv-test-457317-3c044c3cb6f0.json")
  region  = var.region
}
