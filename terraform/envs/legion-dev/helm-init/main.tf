########################################################
# HELM Init
########################################################
module "helm_init" {
  source                      = "../../../modules/gcp/helm-init"
  config_context_auth_info    = "${var.config_context_auth_info}"
  config_context_cluster      = "${var.config_context_cluster}"
}
