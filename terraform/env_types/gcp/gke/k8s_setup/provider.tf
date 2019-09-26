provider "azurerm" {
  version = "1.33.1"
}

provider "google" {
  version = "2.16.0"
}

provider "aws" {
  version = "2.28.1"
}

provider "helm" {
  version         = "0.10.2"
  namespace       = "kube-system"
  service_account = "tiller"
}

provider "kubernetes" {
  version                  = "1.9.0"
  config_context_auth_info = var.config_context_auth_info
  config_context_cluster   = var.config_context_cluster
}

provider "null" {
  version = "~> 2.1.2"
}

provider "template" {
  version = "~> 2.1.2"
}