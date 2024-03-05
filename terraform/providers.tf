terraform {
  cloud {
    organization = "mahwill29"
    ## Required for Terraform Enterprise; Defaults to app.terraform.io for Terraform Cloud
    hostname = "app.terraform.io"

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
    client_certificate     = base64decode(data.azurerm_kubernetes_cluster.default.kube_config.0.client_certificate)
    client_key             = base64decode(data.azurerm_kubernetes_cluster.default.kube_config.0.client_key)
    cluster_ca_certificate = base64decode(data.azurerm_kubernetes_cluster.default.kube_config.0.cluster_ca_certificate)
  }
}

provider "kubernetes" {
  host                   = data.azurerm_kubernetes_cluster.default.kube_config.0.host
  client_certificate     = base64decode(data.azurerm_kubernetes_cluster.default.kube_config.0.client_certificate)
  client_key             = base64decode(data.azurerm_kubernetes_cluster.default.kube_config.0.client_key)
  cluster_ca_certificate = base64decode(data.azurerm_kubernetes_cluster.default.kube_config.0.cluster_ca_certificate)
}


