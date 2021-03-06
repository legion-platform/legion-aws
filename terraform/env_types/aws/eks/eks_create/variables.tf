##################
# Common
##################
variable "cluster_name" {
  default     = "legion"
  description = "Legion cluster name"
}

variable "root_domain" {
  description = "Legion cluster root domain"
}
variable "infra_cidr" {
  description = "Infrastructure network CIDR to peering with"
}
variable "k8s_version" {
  default     = "1.13.10"
  description = "Kubernetes master version"
}
variable "allowed_ips" {
  description = "CIDR to allow access from"
}
variable "agent_cidr" {
  default     = "0.0.0.0/0"
  description = "Jenkins agent CIDR to allow access for CI jobs or your WAN address in case of locla run"
}
variable "dns_zone_name" {
  description = "Cluster root DNS zone name"
}

##################
# GCP
##################
variable "project_id" {
  description = "GCP project ID"
}
variable "region" {
  description = "GCP region"
}
variable "zone" {
  default     = ""
  description = "GCP zone"
}

##################
# AWS
##################
variable "az_list" {
  description = "AWS profile name"
}
variable "aws_credentials_file" {
  default     = "~/.aws/credentials"
  description = "AWS credentials file location"
}
variable "region_aws" {
  default     = "eu-central-1"
  description = "Region of AWS resources"
}
variable "aws_region" {
  default     = "eu-central-1"
  description = "Region of AWS resources"
}
variable "cidr" {
  default     = []
  description = "network CIDR"
}
variable "private_subnet_cidrs" {
  default     = []
  description = "network CIDR"
}
variable "public_subnet_cidrs" {
  default     = []
  description = "AWS public network CIDR, will be used to place ELB"
}
variable "nat_subnet_cidr" {
  default     = ""
  description = "AWS NAT network CIDR, will be used to place bastion host"
}

#############
# Node pool
#############
variable "node_disk_size_gb" {
  default     = "20"
  description = "Persistent disk size for cluster worker nodes"
}
variable "gke_node_machine_type" {
  default     = "n1-standard-2"
  description = "Machine type of GKE nodes"
}
variable "gke_num_nodes_min" {
  default     = "1"
  description = "Number of nodes in each GKE cluster zone"
}
variable "gke_num_nodes_max" {
  default     = "5"
  description = "Number of nodes in each GKE cluster zone"
}
variable "nodes_sa" {
  default     = "default"
  description = "Service account for cluster nodes"
}

################
# Bastion host
################
variable "bastion_machine_type" {
  default = "f1-micro"
}
variable "bastion_tag" {
  default     = ""
  description = "Bastion network tags"
}
variable "bastion_hostname" {
  default     = "bastion"
  description = "bastion hostname"
}
