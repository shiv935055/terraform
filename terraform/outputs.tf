# outputs.tf
output "gke_cluster_name" {
  value = module.gke_bastion.gke_cluster_name
}
output "gke_cluster_endpoint" {
  value = module.gke_bastion.gke_cluster_endpoint
}
output "gke_cluster_master_version" {
  value = module.gke_bastion.gke_cluster_master_version
}
output "bastion_ip" {
  value = module.gke_bastion.bastion_ip
}
