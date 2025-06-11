module "gke_bastion" {
  source = "./modules/gke-bastion"

  project_id             = var.project_id
  region                 = var.region
  cluster_name           = var.cluster_name
  vpc_name               = var.vpc_name
  subnet_name            = var.subnet_name
  gke_node_cidr          = var.gke_node_cidr
  pods_cidr              = var.pods_cidr
  svc_cidr               = var.svc_cidr
  master_ipv4_cidr_block = var.master_ipv4_cidr_block

  bastion_name           = var.bastion_name
  bastion_machine_type   = var.bastion_machine_type
  bastion_image          = var.bastion_image
  bastion_startup_script = var.bastion_startup_script
  bastion_tags           = var.bastion_tags

  firewall_name            = var.firewall_name
  firewall_ports           = var.firewall_ports
  firewall_source_ranges   = var.firewall_source_ranges
  firewall_target_tags     = var.firewall_target_tags

  nat_router_name        = var.nat_router_name
  nat_name               = var.nat_name
  global_ip_name         = var.global_ip_name

  service_account_roles  = var.service_account_roles
}
