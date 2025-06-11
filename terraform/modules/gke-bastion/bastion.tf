resource "google_compute_instance" "bastion" {
  name         = var.bastion_name
  machine_type = var.bastion_machine_type
  zone         = "${var.region}-a"

  boot_disk {
    initialize_params {
      image = var.bastion_image
    }
  }

  network_interface {
    network    = google_compute_network.vpc_network.self_link
    subnetwork = google_compute_subnetwork.subnetwork.self_link
    access_config {}
  }

  metadata_startup_script = var.bastion_startup_script
  tags                    = var.bastion_tags

  service_account {
    email  = google_service_account.bastion_sa.email
    scopes = ["cloud-platform"] # You can replace this with limited scopes if preferred
  }
}

resource "google_compute_firewall" "allow_ssh_bastion" {
  name    = var.firewall_name
  network = google_compute_network.vpc_network.self_link

  allow {
    protocol = "tcp"
    ports    = var.firewall_ports
  }

  source_ranges = var.firewall_source_ranges
  target_tags   = var.firewall_target_tags
}

resource "google_service_account" "bastion_sa" {
  account_id   = "bastion-sa"
  display_name = "Bastion Service Account"
}

resource "google_project_iam_member" "bastion_sa_roles" {
  for_each = toset(var.service_account_roles)
  project  = var.project_id
  member   = "serviceAccount:${google_service_account.bastion_sa.email}"
  role     = each.value
}
