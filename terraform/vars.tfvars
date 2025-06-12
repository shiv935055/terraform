# vars.tfvars
project_id = "shiv-test-457317"
region = "asia-south1"
cluster_name = "tf-test-cluster"
vpc_name = "tf-vpc"
subnet_name = "tf-subnet"
gke_node_cidr = "10.0.15.0/24"
pods_cidr = "10.0.16.0/24"
svc_cidr = "10.0.17.0/24"
master_ipv4_cidr_block = "10.0.18.0/28"
nat_router_name = "tf-nat-router"
nat_name = "tf-nat"
global_ip_name = "tf-nat-ip"
bastion_name = "tf-bastion"
bastion_machine_type = "e2-medium"
bastion_image = "ubuntu-2004-lts"
bastion_startup_script = <<-EOT
  #!/bin/bash
  sudo apt-get update
  sudo apt-get install -yq git
  bash <(curl -fsS https://packages.openvpn.net/as/install.sh) --yes
EOT
bastion_tags = ["tf-bastion"]
firewall_name = "allow-ssh-tf-bastion"
firewall_ports = ["22"]
firewall_source_ranges = ["0.0.0.0/0"]
firewall_target_tags = ["bastion"]
service_account_roles = [
  "roles/logging.logWriter",
  "roles/monitoring.metricWriter",
  "roles/monitoring.viewer",
  "roles/compute.osLogin",
  "roles/compute.admin",
  "roles/iam.serviceAccountUser",
  "roles/container.admin",
  "roles/container.clusterAdmin",
  "roles/compute.osAdminLogin"
]
