resource "azurerm_kubernetes_cluster" "this" {

  name                = var.name
  location            = var.location
  resource_group_name = var.resource_group_name

  dns_prefix = var.name

  sku_tier = "Free"

  kubernetes_version = var.kubernetes_version

  identity {
    type = "SystemAssigned"
  }

  default_node_pool {

    name = "system"

    vm_size = var.vm_size

    node_count = 1

    type = "VirtualMachineScaleSets"

    only_critical_addons_enabled = true

    os_disk_size_gb = 30

    # upgrade_settings {
    #   max_surge = "0"
    # }
  }

  network_profile {

    network_plugin = "azure"

    network_plugin_mode = "overlay"

    network_policy = "azure"

    load_balancer_sku = "standard"

    outbound_type = "loadBalancer"
  }

  role_based_access_control_enabled = true

  oidc_issuer_enabled = true

  workload_identity_enabled = true

  azure_policy_enabled = false

  tags = var.tags
}