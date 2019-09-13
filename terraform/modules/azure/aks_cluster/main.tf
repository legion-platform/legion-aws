########################################################
# Deploy AKS cluster
########################################################

resource "azurerm_kubernetes_cluster" "aks" {
  count               = length(var.node_pools) > 0 ? 1 : 0
  name                = var.cluster_name
  location            = var.location
  resource_group_name = var.resource_group
  # https://github.com/Azure/AKS/issues/3
  # There's additional resource group created, that used to represent and hold the lifecycle of 
  # k8s cluster resources. We only can set a name for it.
  node_resource_group = "${var.resource_group}-k8s"
  dns_prefix          = var.aks_dns_prefix
  kubernetes_version  = var.k8s_version
  
  linux_profile {
    admin_username = var.ssh_user
    ssh_key {
      key_data = var.ssh_public_key
    }
  }

  dynamic "agent_pool_profile" {
    for_each = var.node_pools
    content {
      type                = "VirtualMachineScaleSets"
      enable_auto_scaling = true

      name            = lookup(agent_pool_profile.value, "name", "base")
      vm_size         = lookup(agent_pool_profile.value.node_config, "machine_type", "Standard_B2s")
      os_type         = "Linux"
      os_disk_size_gb = lookup(agent_pool_profile.value.node_config, "disk_size_gb", "30")
      vnet_subnet_id  = var.aks_subnet_id

      count     = lookup(agent_pool_profile.value, "initial_node_count", "1")
      min_count = lookup(lookup(agent_pool_profile.value, "autoscaling", {}), "min_node_count", "1")
      max_count = lookup(lookup(agent_pool_profile.value, "autoscaling", {}), "max_node_count", "2")
      max_pods  = lookup(agent_pool_profile.value, "max_pods", "32")

      node_taints = [
        for taint in lookup(agent_pool_profile.value.node_config, "taint", []):
          "${taint.key}=${taint.value}:${taint.effect}"
      ]
    }
  }

  # We have to provide Service Principal account credentials in order to create node resource group
  # and appropriate dynamic resources, related to AKS (node resource groups, network security groups,
  # virtual machine scale sets, loadbalancers)
  service_principal {
    client_id     = var.sp_id
    client_secret = var.sp_secret
  }

  addon_profile {
    oms_agent {
      enabled                    = true
      log_analytics_workspace_id = var.aks_analytics_workspace_id
    }
  }

  role_based_access_control {
    enabled = true
  }

  network_profile {
    network_plugin = "azure"
    network_policy = "calico"
    #pod_cidr: ""
    #service_cidr: "10.0.0.0/16"
    #dns_service_ip: "10.0.0.10"
    #docker_bridge_cidr: "172.17.0.1/16"
    #load_balancer_sku: "basic"
  }

  tags = var.aks_tags
}
