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
    admin_enabled            = false
}

resource "azurerm_kubernetes_cluster" "aks_cluster" {
    name                = "productconsilium-aks"
    location            = azurerm_resource_group.aks_rg.location
    resource_group_name = azurerm_resource_group.aks_rg.name
    dns_prefix          = "productconsilium"

    default_node_pool {
        name                = "default"
        node_count          = 1
        vm_size             = "Standard_B1s"
        enable_auto_scaling = false
        temporary_name_for_rotation   = "temp"
    }

    identity {
        type = "SystemAssigned"
    }
}

module "kubernetes" {
    source = "./kubernetes_module"
    host                   = azurerm_kubernetes_cluster.aks_cluster.kube_config.0.host
    username               = azurerm_kubernetes_cluster.aks_cluster.kube_config.0.username
    password               = azurerm_kubernetes_cluster.aks_cluster.kube_config.0.password
    client_certificate     = base64decode(azurerm_kubernetes_cluster.aks_cluster.kube_config.0.client_certificate)
    client_key             = base64decode(azurerm_kubernetes_cluster.aks_cluster.kube_config.0.client_key)
    cluster_ca_certificate = base64decode(azurerm_kubernetes_cluster.aks_cluster.kube_config.0.cluster_ca_certificate)
}

