##################
# Common
##################
variable "cluster_type" {
  description = "Cloud provider"
}

variable "tls_key" {
  description = "TLS key for Legion cluster"
}

variable "tls_crt" {
  description = "TLS certificate file for Legion cluster"
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
variable "public_subnet_cidrs" {
  default = []
}
variable "config_context_auth_info" {
  description = "Legion cluster context auth"
}

variable "config_context_cluster" {
  description = "Legion cluster context name"
}

variable "aws_region" {
  default     = "eu-central-1"
  description = "Region of AWS resources"
}

variable "az_list" {
  description = "AWS AZ list to use"
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

variable "dns_zone_name" {
  description = "Cluster root DNS zone name"
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

variable "storage_class" {
  default     = "gp2"
  description = "Grafana storage class"
}

variable "cluster_context" {
  description = "Kubectl cluster context"
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

