data "azurerm_kubernetes_cluster" "aks" {
  name                = var.cluster_name
  resource_group_name = var.azure_resource_group
}

data "azurerm_public_ip" "aks_ext" {
  name                = var.aks_public_ip_name
  resource_group_name = var.azure_resource_group
}

locals {
  config_context_auth_info = data.azurerm_kubernetes_cluster.aks.kube_config.0.username
  config_context_cluster   = var.cluster_name
}

module "get_tls" {
  source = "../../../../modules/tls"
  secrets_storage = var.secrets_storage
  cluster_name    = var.cluster_name
}

########################################################
# K8S setup
########################################################
module "base_setup" {
  source          = "../../../../modules/k8s/base_setup"
  cluster_name    = var.cluster_name
  tls_key         = module.get_tls.tls_secret_key
  tls_crt         = module.get_tls.tls_secret_crt
}

module "nginx-ingress" {
  source            = "../../../../modules/k8s/nginx-ingress"
  ingress_ip        = data.azurerm_public_ip.aks_ext.ip_address
  ip_resource_group = var.azure_resource_group
  replicas          = data.azurerm_kubernetes_cluster.aks.agent_pool_profile.0.min_count
}

# module "dashboard" {
#   source                    = "../../../../modules/k8s/dashboard"
#   cluster_name              = var.cluster_name
#   root_domain               = var.root_domain
#   tls_secret_key            = module.base_setup.tls_secret_key
#   tls_secret_crt            = module.base_setup.tls_secret_crt
# }

module "auth" {
  source                = "../../../../modules/k8s/auth"
  cluster_name          = var.cluster_name
  root_domain           = var.root_domain
  oauth_client_id       = var.oauth_client_id
  oauth_client_secret   = var.oauth_client_secret
  oauth_redirect_url    = "https://auth.${var.cluster_name}.${var.root_domain}/oauth2/callback"
  oauth_oidc_issuer_url = "${var.keycloak_url}/auth/realms/${var.keycloak_realm}"
  oauth_oidc_audience   = var.keycloak_realm_audience
  oauth_cookie_expire   = "168h0m0s"
  oauth_cookie_secret   = var.oauth_cookie_secret
  oauth_oidc_scope      = var.oauth_scope
}

module "monitoring" {
  source                = "../../../../modules/k8s/monitoring"
  cluster_name          = var.cluster_name
  legion_infra_version  = var.legion_infra_version
  alert_slack_url       = var.alert_slack_url
  root_domain           = var.root_domain
  grafana_admin         = var.grafana_admin
  grafana_pass          = var.grafana_pass
  grafana_storage_class = var.grafana_storage_class
  docker_repo           = var.docker_repo
  monitoring_namespace  = var.monitoring_namespace
  tls_secret_key        = module.get_tls.tls_secret_key
  tls_secret_crt        = module.get_tls.tls_secret_crt
}

module "istio" {
  source               = "../../../../modules/k8s/istio"
  root_domain          = var.root_domain
  cluster_name         = var.cluster_name
  istio_namespace      = var.istio_namespace
  monitoring_namespace = var.monitoring_namespace
  knative_namespace    = var.knative_namespace
  tls_secret_key       = module.get_tls.tls_secret_key
  tls_secret_crt       = module.get_tls.tls_secret_crt
  legion_infra_version = var.legion_infra_version
}

# module "gke-saa" {
#   source                    = "../../../../modules/k8s/gke-saa"
#   legion_helm_repo          = var.legion_helm_repo
#   legion_infra_version      = var.legion_infra_version
# }
