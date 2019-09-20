##################
# Common
##################
variable "azure_resource_group" {
  description = "Azure base resource group name"
  default     = ""
}

variable "aks_public_ip_name" {
  description = "Name of public IP-address used for AKS cluster"
}

variable "cluster_type" {
  default     = "azure/aks"
  description = "Legion cluster cloud provider type"
}

variable "project_id" {
  description = "Target project id"
}

variable "zone" {
  default     = "us-east1-b"
  description = "Default zone"
}

variable "region" {
  default     = "us-east1"
  description = "Region of resources"
}

variable "config_context_auth_info" {
  default     = ""
  description = "Legion cluster context auth"
}

variable "config_context_cluster" {
  default     = ""
  description = "Legion cluster context name"
}

variable "region_aws" {
  default     = "us-east-2"
  description = "Region of AWS resources"
}

variable "aws_profile" {
  description = "AWS profile name"
}

variable "aws_credentials_file" {
  default     = "~/.aws/config"
  description = "AWS credentials file location"
}

variable "secrets_storage" {
  description = "Cluster secrets storage"
}

variable "cluster_name" {
  default     = "legion"
  description = "Legion cluster name"
}

variable "legion_helm_repo" {
  description = "Legion helm repo"
}

variable "legion_infra_version" {
  description = "Legion infra release version"
}

variable "root_domain" {
  description = "Legion cluster root domain"
}

variable "docker_repo" {
  description = "Legion Docker repo url"
}

########################
# Prometheus monitoring
########################
variable "allowed_ips" {
  type        = list(string)
  description = "CIDR to allow access from"
}

variable "alert_slack_url" {
  description = "Alert slack usrl"
}

variable "grafana_admin" {
  description = "Grafana admion username"
}

variable "grafana_pass" {
  description = "Grafana admin password"
}

variable "grafana_storage_class" {
  default     = "default"
  description = "Grafana storage class"
}

variable "monitoring_namespace" {
  default     = "kube-monitoring"
  description = "clusterwide monitoring namespace"
}

##################
# OAuth2
##################
variable "oauth_client_id" {
  description = "OAuth2 Client ID"
}

variable "oauth_client_secret" {
  description = "OAuth2 Client Secret"
}

variable "oauth_cookie_secret" {
  description = "OAuth2 Cookie Secret"
}

variable "keycloak_realm" {
  description = "Keycloak realm"
}

variable "keycloak_url" {
  description = "Keycloak URL"
}

variable "keycloak_realm_audience" {
  description = "Keycloak real audience"
}

variable "oauth_scope" {
  description = "Scope for OAuth"
}

########################
# Istio
########################
variable "istio_namespace" {
  default     = "istio-system"
  description = "istio namespace"
}

