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
    use_oidc = true
}

data "azurerm_kubernetes_cluster" "default" {
  depends_on          = [module.aks] # refresh cluster state before reading
  name                = "productconsilium-aks"
  resource_group_name = "product-consilium-resource-group"
}

provider "helm" {
  kubernetes {
    host                   = data.azurerm_kubernetes_cluster.default.kube_config.0.host
    client_certificate     = data.azurerm_kubernetes_cluster.default.kube_config.0.client_certificate
    client_key             = data.azurerm_kubernetes_cluster.default.kube_config.0.client_key
    cluster_ca_certificate = data.azurerm_kubernetes_cluster.default.kube_config.0.cluster_ca_certificate
  }
}

provider "kubernetes" {
  host                   = data.azurerm_kubernetes_cluster.default.kube_config.0.host
  client_certificate     = data.azurerm_kubernetes_cluster.default.kube_config.0.client_certificate
  client_key             = data.azurerm_kubernetes_cluster.default.kube_config.0.client_key
  cluster_ca_certificate = data.azurerm_kubernetes_cluster.default.kube_config.0.cluster_ca_certificate
}


