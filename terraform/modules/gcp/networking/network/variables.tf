
variable "project_id" {
  description = "Target project id"
}
variable "cluster_name" {
  default     = "legion"
  description = "Legion cluster name"
}
variable "zone" {
  description = "Default zone"
}
variable "region" {
  description = "Region of resources"
}
variable "subnet_cidr" {
  default     = "10.0.0.0/24"
  description = "Subnet range"
}
