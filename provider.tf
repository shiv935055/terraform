provider "google" {
  project = var.project_id
  credentials = file("/root/shiv-test-457317-3c044c3cb6f0.json")
  region  = var.region
}
