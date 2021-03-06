variable "project_id" {
  description = "Target project id"
}

variable "cluster_name" {
  default     = "legion"
  description = "Legion cluster name"
}

variable "region" {
  description = "Region of resources"
}

variable "subnet_cidr" {
  description = "Subnet range"
}
