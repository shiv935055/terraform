# vars.tfvars
project_id = "your-project-id"
region = "your-region"
cluster_name = "your-cluster-name"
vpc_name = "your-vpc-name"
subnet_name = "your-subnet-name"
gke_node_cidr = "your-node-cidr"
pods_cidr = "your-pods-cidr"
svc_cidr = "your-sv-cidr"
master_ipv4_cidr_block = "your-gke-master-cidr-block"
nat_router_name = "your-nat-router-name"
nat_name = "your-nat-name"
global_ip_name = "your-global-ip-name"
bastion_name = "your-bastion-vm-name"
bastion_machine_type = "e2-medium"
bastion_image = "ubuntu-2004-lts"
bastion_startup_script = <<-EOT
  #!/bin/bash
  sudo apt-get update
  sudo apt-get install -yq git
EOT
bastion_tags = ["bastion"]
firewall_name = "allow-ssh-bastion"
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
