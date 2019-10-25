variable "cluster_name" {
  description = "Legion k8s cluster name"
  default     = "legion"
}

variable "location" {
  description = "Azure location where the resource group should be created"
}

variable "resource_group" {
  description = "The name of the resource group, unique within Azure subscription"
  default     = "testResourceGroup1"
}

variable "k8s_version" {
  default     = "1.14.6"
  description = "Version of Kubernetes engine"
}

variable "ssh_user" {
  default     = "ubuntu"
  description = "Default ssh user"
}

variable "ssh_public_key" {
  description = "SSH public key provided to default ssh user"
}

variable "aks_dns_prefix" {
  description = "DNS prefix specified when creating the cluster"
  default     = "k8stest"
}

variable "aks_subnet_id" {
  description = "ID of subnet for the cluster nodes to run"
}

variable "aks_tags" {
  description = "Tags used for Azure Kubernetes cluster definition"
  default     = {}
  type        = "map"
}

variable "aks_analytics_workspace_id" {
  description = "Azure Log Analytics workspace ID"
  default     = "my-test-default-variable-eica0Chi"
}

variable "sp_client_id" {
  description = "Service Principal account ID"
}

variable "sp_secret" {
  description = "Service Principal account secret"
}

variable "public_ip_name" {
  description = "Name of public IP-address used for AKS cluster"
}

variable "bastion_ip_name" {
  description = "Name of public IP-address of AKS cluster bastion host"
}

variable "allowed_ips" {
  description = "CIDRs to allow access from"
}

variable "node_pools" {
  description = "List of k8s node pools map definitions"
  default     = []
}
