# outputs.tf (module)
output "gke_cluster_name" {
  value = google_container_cluster.primary.name
}
output "gke_cluster_endpoint" {
  value = google_container_cluster.primary.endpoint
}
output "gke_cluster_master_version" {
  value = google_container_cluster.primary.master_version
}
output "bastion_ip" {
  value = google_compute_instance.bastion.network_interface[0].access_config[0].nat_ip
}
