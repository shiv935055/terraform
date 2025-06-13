variable "project_id" {
  description = "The GCP project ID"
  type        = string
}

variable "region" {
  description = "The GCP region"
  type        = string
}

variable "zone" {
  description = "The GCP zone"
  type        = string
}

variable "cluster_name" {
  description = "GKE cluster name"
  type        = string
}

variable "vpc_name" {
  description = "VPC network name"
  type        = string
}

variable "subnet_name" {
  description = "Subnet name"
  type        = string
}

variable "gke_node_cidr" {
  description = "Primary CIDR for the GKE nodes subnet"
  type        = string
}

variable "pods_cidr" {
  description = "Secondary IP range for pods"
  type        = string
}

variable "svc_cidr" {
  description = "Secondary IP range for services"
  type        = string
}

variable "bastion_name" {
  description = "Bastion host name"
  type        = string
}

variable "master_ipv4_cidr_block" {
  description = "Master CIDR block"
  type        = string
}
