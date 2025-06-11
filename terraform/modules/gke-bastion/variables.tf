# variables.tf
variable "project_id" { type = string }
variable "region"     { type = string }
variable "cluster_name" { type = string }
variable "vpc_name"    { type = string }
variable "subnet_name" { type = string }
variable "gke_node_cidr" { type = string }
variable "pods_cidr" { type = string }
variable "svc_cidr" { type = string }
variable "master_ipv4_cidr_block" { type = string }

variable "bastion_name" { type = string }
variable "bastion_machine_type" { type = string }
variable "bastion_image" { type = string }
variable "bastion_startup_script" { type = string }
variable "bastion_tags" { type = list(string) }

variable "firewall_name" { type = string }
variable "firewall_ports" { type = list(string) }
variable "firewall_source_ranges" { type = list(string) }
variable "firewall_target_tags" { type = list(string) }

variable "nat_router_name" { type = string }
variable "nat_name" { type = string }
variable "global_ip_name" { type = string }

variable "service_account_roles" { type = list(string) }
