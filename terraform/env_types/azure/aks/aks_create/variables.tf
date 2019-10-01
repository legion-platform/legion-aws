############################################################################################################

variable "azure_location" {
  default     = "eastus"
  description = "Azure location in which the resource group will be created"
}

variable "azure_resource_group" {
  default     = "legion-rg"
  description = "Azure base resource group name"
}

############################################################################################################

variable "aks_analytics_workspace_id" {
  default     = "my-test-default-variable-eica0Chi"
  description = "Azure Log Analytics workspace ID"
}

variable "cluster_name" {
  default     = "legion"
  description = "Legion k8s cluster name"
}

variable "aks_common_tags" {
  description = "Set of common tags assigned to all cluster resources"
  type        = "map"
  default     = {
    environment = "Development"
    purpose     = "Kubernetes Cluster"
  }
}

variable "aks_public_ip_name" {
  description = "Name of public IP-address used for AKS cluster"
}

variable "aks_dns_prefix" {
  default     = ""
  description = "DNS prefix for Kubernetes cluster"
}

variable "aks_cidr" {
  default     = "10.255.255.0/24"
  description = "Overall VPC address space for all subnets in it"
}

variable "k8s_version" {
  default     = "1.13.10"
  description = "Kubernetes master version"
}

variable "allowed_ips" {
  description = "CIDRs to allow access from"
}

# Next two variables are ID and secret of Service Principal account.
# These should be defined as TF_VAR_sp_client_id and TF_VAR_sp_secret environment variables
variable "sp_client_id" {
  description = "Service Principal account ID"
}

variable "sp_secret" {
  description = "Service Principal account secret"
}

variable "ssh_key" {
  description = "SSH public key for Legion cluster nodes and bastion host"
}

################
# Bastion host
################
variable "bastion_machine_type" {
  default = "Standard_B1ls"
}

variable "bastion_tags" {
  default     = {}
  description = "Bastion host tags"
  type        = "map"
}

variable "bastion_hostname" {
  default     = "bastion"
  description = "bastion hostname"
}

################
# k8s node pools
################
variable "node_pools" {
  default = [
    {
      name               = "main"
      initial_node_count = "4"
      max_pods           = "64"
      autoscaling = {
        min_node_count   = "1"
        max_node_count   = "5"
      }
      node_config = {
        machine_type     = "Standard_B2s"
      }
    },
    {
      name               = "training"
      max_pods           = "128"
      autoscaling = {
        min_node_count   = "1"
        max_node_count   = "2"
      }
      node_config = {
        machine_type     = "Standard_B8ms"
        disk_size_gb     = "100"
        labels = {
          mode           = "legion-training"
        }
        taint = [{
          key    = "dedicated"
          value  = "training"
          effect = "NoSchedule"
        }]
      }
    },
    {
      # Pool name must start with a lowercase letter, have max length of 12, and only have characters a-z0-9
      name     = "traininggpu"
      max_pods = "128"
      node_config = {
        machine_type = "Standard_NC6_Promo" # East US, South Central US, North Central US, North Europe, UK South
        disk_size_gb = "100"
        labels = {
          "mode" = "legion-training-gpu"
        }
      }
    }
  ]
}