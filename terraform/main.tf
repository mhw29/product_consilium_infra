


resource "azurerm_dns_zone" "hosted_zone" {
    name                = "productconsilium.com"
    resource_group_name = azurerm_resource_group.aks_rg.name
}

resource "azurerm_container_registry" "acr" {
    name                     = "productconsilium"
    resource_group_name      = azurerm_resource_group.aks_rg.name
    location                 = azurerm_resource_group.aks_rg.location
    sku                      = "Standard"
    admin_enabled            = true
}



data "azurerm_client_config" "current" {}

output "tenant_id" {
  value = data.azurerm_client_config.current.tenant_id
}








# Will revisit this.

# # Use the ACR's ID to get its Resource ID
# data "azurerm_container_registry" "acr" {
#   name                = azurerm_container_registry.acr.name
#   resource_group_name = azurerm_resource_group.aks_rg.name
# }

# # Grant the AKS cluster's managed identity access to pull from the ACR
# resource "azurerm_role_assignment" "acr_pull_role" {
#   scope                = data.azurerm_container_registry.acr.id
#   role_definition_name = "AcrPull"
#   principal_id         = azurerm_kubernetes_cluster.aks_cluster.kubelet_identity[0].object_id
# }

module "kubernetes" {
    source = "./kubernetes"
    host                   = azurerm_kubernetes_cluster.aks_cluster.kube_config.0.host
    username               = azurerm_kubernetes_cluster.aks_cluster.kube_config.0.username
    password               = azurerm_kubernetes_cluster.aks_cluster.kube_config.0.password
    client_certificate     = base64decode(azurerm_kubernetes_cluster.aks_cluster.kube_config.0.client_certificate)
    client_key             = base64decode(azurerm_kubernetes_cluster.aks_cluster.kube_config.0.client_key)
    cluster_ca_certificate = base64decode(azurerm_kubernetes_cluster.aks_cluster.kube_config.0.cluster_ca_certificate)
}

module "aks" {
  source = "./azure/aks"

  depends_on = [
    azurerm_resource_group.current
  ]
}

module "postgres" {
    source = "./azure/postgres"
    depends_on = [
        azurerm_resource_group.current
    ]
}

resource "azurerm_resource_group" "current" {
    name     = "productconsilium"
    location = "centralus"
}

resource "azurerm_role_assignment" "key_vault_secrets_user" {
  scope                = azurerm_key_vault.key_vault.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_kubernetes_cluster.aks_cluster.identity[0].principal_id
}
