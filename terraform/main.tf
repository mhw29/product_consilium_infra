terraform {
        backend "remote" {
                organization = "mahwill29"

                workspaces {
                        name = "product-consilium-dev"
                }
        }
}

provider "azurerm" {
        features {}
}

resource "azurerm_resource_group" "aks_rg" {
    name     = "product-consilium-resource-group"
    location = "centralus"
}


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

resource "azurerm_kubernetes_cluster" "aks_cluster" {
    name                = "productconsilium-aks"
    location            = azurerm_resource_group.aks_rg.location
    resource_group_name = azurerm_resource_group.aks_rg.name
    dns_prefix          = "productconsilium"

    default_node_pool {
        name                = "default"
        node_count          = 1
        vm_size             = "Standard_B2s"
        enable_auto_scaling = false
    }

    identity {
        type = "SystemAssigned"
    }

    key_vault_secrets_provider {
        secret_rotation_enabled = true
        secret_rotation_interval = "2m"
    }
}

data "azurerm_client_config" "current" {}

output "tenant_id" {
  value = data.azurerm_client_config.current.tenant_id
}

resource "azurerm_key_vault" "key_vault" {
    name                        = "productconsiliumkv"
    location                    = azurerm_resource_group.aks_rg.location
    resource_group_name         = azurerm_resource_group.aks_rg.name
    tenant_id                   = data.azurerm_client_config.current.tenant_id
    sku_name                    = "standard"
    enable_rbac_authorization   = true

    soft_delete_retention_days  = 7
    purge_protection_enabled    = false

    network_acls {
        default_action             = "Allow"
        bypass                     = "AzureServices"
    }

    access_policy {
        tenant_id = data.azurerm_client_config.current.tenant_id
        object_id = azurerm_kubernetes_cluster.aks_cluster.kubelet_identity[0].object_id

        key_permissions = [
            "Get","List"
        ]

        secret_permissions = [
            "Get","List"
        ]

        certificate_permissions = [
            "Get","List"
        ]
    }
}

resource "azurerm_role_assignment" "key_vault_secrets_user" {
  scope                = azurerm_key_vault.key_vault.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_kubernetes_cluster.aks_cluster.identity[0].principal_id
}

resource "azurerm_postgresql_server" "postgres_db" {
    name                          = "productconsilium-postgres"
    location                      = azurerm_resource_group.aks_rg.location
    resource_group_name           = azurerm_resource_group.aks_rg.name
    sku_name                      = "B_Gen5_1"
    storage_mb                    = 5120
    version                       = "11"
    administrator_login           = var.postgres_username
    administrator_login_password  = var.postgres_password
    ssl_enforcement_enabled       = true
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
    source = "./kubernetes_module"
    host                   = azurerm_kubernetes_cluster.aks_cluster.kube_config.0.host
    username               = azurerm_kubernetes_cluster.aks_cluster.kube_config.0.username
    password               = azurerm_kubernetes_cluster.aks_cluster.kube_config.0.password
    client_certificate     = base64decode(azurerm_kubernetes_cluster.aks_cluster.kube_config.0.client_certificate)
    client_key             = base64decode(azurerm_kubernetes_cluster.aks_cluster.kube_config.0.client_key)
    cluster_ca_certificate = base64decode(azurerm_kubernetes_cluster.aks_cluster.kube_config.0.cluster_ca_certificate)
}


