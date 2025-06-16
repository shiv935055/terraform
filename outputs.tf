output "cluster_name" {
  value = google_container_cluster.private_cluster.name
}

output "bastion_public_ip" {
  value = google_compute_instance.bastion.network_interface.0.access_config.0.nat_ip
}

output "nat_static_ip" {
  value = google_compute_address.nat_static_ip.address
}

output "cluster_endpoint" {
  value = google_container_cluster.private_cluster.endpoint
}

output "vpc_name" {
  value = google_compute_network.vpc_network.name
}

output "subnet_name" {
  value = google_compute_subnetwork.subnetwork.name
}
