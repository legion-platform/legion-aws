locals {
  common_tags = merge(
    { "cluster" = var.cluster_name },
    var.aks_common_tags
  )
}

########################################################
# Retrieve SSH key from secrets_storage
# TODO: move to separate module
########################################################

data "aws_s3_bucket_object" "ssh_public_key" {
  bucket = var.secrets_storage
  key    = "${var.cluster_name}/ssh/${var.cluster_name}.pub"
}

data "azurerm_public_ip" "aks_ext" {
  name                = var.public_ip_name
  resource_group_name = var.azure_resource_group
}

module "azure_monitoring" {
  source   = "../../../../modules/azure/monitoring"
  cluster_name   = var.cluster_name
  tags           = local.common_tags
  location       = var.azure_location
  resource_group = var.azure_resource_group
}

module "aks_networking" {
  source         = "../../../../modules/azure/networking"
  cluster_name   = var.cluster_name
  tags           = local.common_tags
  location       = var.azure_location
  resource_group = var.azure_resource_group
  subnet_cidr    = var.aks_cidr
  public_ip_name = var.public_ip_name
  allowed_ips    = var.allowed_ips
}

module "aks_bastion" {
  source           = "../../../../modules/azure/bastion"
  cluster_name     = var.cluster_name
  location         = var.azure_location
  resource_group   = var.azure_resource_group
  aks_subnet_id    = module.aks_networking.subnet_id
  public_ip_id     = module.aks_networking.bastion_ip_id
  bastion_ssh_user = "ubuntu"
  bastion_tags     = local.common_tags
}

module "aks_cluster" {
  source                     = "../../../../modules/azure/aks_cluster"
  cluster_name               = var.cluster_name
  aks_tags                   = local.common_tags
  location                   = var.azure_location
  resource_group             = var.azure_resource_group
  aks_dns_prefix             = var.aks_dns_prefix
  aks_subnet_id              = module.aks_networking.subnet_id
  sp_id                      = var.azure_client_id
  sp_secret                  = var.azure_client_secret
  k8s_version                = var.k8s_version
  ssh_user                   = "ubuntu"
  ssh_public_key             = data.aws_s3_bucket_object.ssh_public_key.body
  node_pools                 = var.node_pools
  aks_analytics_workspace_id = module.azure_monitoring.workspace_id
}

resource "local_file" "kubeconfig" {
  sensitive_content = module.aks_cluster.kube_config
  filename          = "/root/.kube/config"
}

resource "null_resource" "bastion_kubeconfig" {
  connection {
    host        = module.aks_networking.bastion_ip
    user        = "ubuntu"
    type        = "ssh"
    private_key = module.aks_bastion.deploy_privkey
    timeout     = "1m"
    agent       = false
  }

  provisioner "remote-exec" {
    inline = [
      "printf \"${data.aws_s3_bucket_object.ssh_public_key.body}\" >> ~/.ssh/authorized_keys",
      "sudo wget -qO /usr/local/bin/kubectl \"https://storage.googleapis.com/kubernetes-release/release/v${var.k8s_version}/bin/linux/amd64/kubectl\"",
      "sudo chmod +x /usr/local/bin/kubectl",
      "mkdir -p ~/.kube && printf \"${module.aks_cluster.kube_config}\" > ~/.kube/config"
    ]
  }
  depends_on = [ module.aks_bastion, module.aks_cluster ]
}