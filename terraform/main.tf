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
    name     = "my-aks-resource-group"
    location = "centralus"
}

resource "azurerm_kubernetes_cluster" "aks_cluster" {
    name                = "aks-vault"
    location            = azurerm_resource_group.aks_rg.location
    resource_group_name = azurerm_resource_group.aks_rg.name
    dns_prefix          = "aksvault"

    default_node_pool {
        name                = "default"
        node_count          = 1
        vm_size             = "Standard_B2s"
        enable_auto_scaling = false
    }
}

