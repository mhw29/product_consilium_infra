# resource "azurerm_kubernetes_cluster" "current" {
#     name                = "productconsilium-aks"
#     location            = azurerm_resource_group.aks_rg.location
#     resource_group_name = azurerm_resource_group.aks_rg.name
#     dns_prefix          = "productconsilium"

#     default_node_pool {
#         name                = "default"
#         node_count          = 1
#         vm_size             = "Standard_B2s"
#         enable_auto_scaling = false
#     }

#     identity {
#         type = "SystemAssigned"
#     }

#     key_vault_secrets_provider {
#         secret_rotation_enabled = true
#         secret_rotation_interval = "2m"
#     }
# }

resource "azurerm_kubernetes_cluster" "current" {
  name                = var.cluster_name
  resource_group_name = var.resource_group_name
  location            = var.resource_group_location
  dns_prefix          = var.dns_prefix

  oidc_issuer_enabled               = var.oidc_issuer_enabled
  role_based_access_control_enabled = true

  default_node_pool {
    name       = var.default_node_pool_name
    node_count = var.default_node_pool_node_count
    vm_size    = var.default_node_pool_vm_size
  }

  identity {
    type = "SystemAssigned"
  }

  tags = var.cluster_tags

}