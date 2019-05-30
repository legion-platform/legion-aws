##################
# Common
##################
variable "project_id" {
  description = "Target project id"
}
variable "cluster_name" {
  default     = "legion"
  description = "Legion cluster name"
}
variable "aws_profile" {
  description = "AWS profile name"
}
variable "aws_credentials_file" {
  default     = "~/.aws/config"
  description = "AWS credentials file location"
}
variable "zone" {
  default     = "us-east1-b"
  description = "Default zone"
}
variable "region" {
  default = "us-east1"
  description = "Region of resources"
}
variable "region_aws" {
  default = "us-east-2"
  description = "Region of AWS resources"
}
variable "secrets_storage" {
  description = "Cluster secrets storage"
}
variable "root_domain" {
  description = "Legion cluster root domain"
}
variable "aws_vpc_id" {
  description = "AWS VPC id to establish peering with"
}
variable "gcp_cidr" {
  description = "GCP network CIDR"
}
variable "aws_sg" {
  description = "AWS SG id for gcp access"
}
variable "aws_cidr" {
  description = "AWS network CIDR"
}
variable "aws_route_table_id" {
  description = "AWS Route table ID"
}
variable "config_context_auth_info" {
  description = "Legion cluster context auth"
}
variable "config_context_cluster" {
  description = "Legion cluster context name"
}

#############
# GKE
#############
variable "location" {
  default = "us-east1-b"
  description = "The location (region or zone) in which the cluster master will be created"
}
variable "k8s_version" {
  default = "1.12.7-gke.7"
  description = "Kubernetes master version"
}
variable "node_version" {
  description = "K8s version for Nodes. If no value is provided, this defaults to the value of k8s_version."
  default     = "1.12.7-gke.7"
}
variable "allowed_ips" {
  description = "CIDR to allow access from"
}
variable "agent_cidr" {
  description = "Jenkins agent CIDR to allow access for CI jobs or your WAN address in case of locla run"
}
variable "dns_zone_name" {
  description = "Cluster root DNS zone name"
}

#############
# Node pool
#############
variable "node_disk_size_gb" {
  default = "20"
  description = "Persistent disk size for cluster worker nodes"
}
variable "gke_node_machine_type" {
  default = "n1-standard-2"
  description = "Machine type of GKE nodes"
}
variable "gke_num_nodes_min" {
  default = "1"
  description = "Number of nodes in each GKE cluster zone"
}
variable "gke_num_nodes_max" {
  default = "5"
  description = "Number of nodes in each GKE cluster zone"
}
variable "nodes_sa" {
  default = "default"
  description = "Service account for cluster nodes"
}
# TODO: custom k8s resources cidrs?
# variable "ip_range_pods" {
#   default = "10.1.1.0/24"
#   description = "The secondary ip range to use for pods"
# }
# variable "ip_range_services" {
#   default = "10.1.2.0/24"
#   description = "The secondary ip range to use for pods"
# }

################
# Bastion host
################
variable "bastion_machine_type" {
  default = "f1-micro"
}
variable "bastion_tags" {
  default = ""
  description = "Bastion network tags"
}
variable "bastion_hostname" {
  default = "bastion"
  description = "bastion hpstname"
}