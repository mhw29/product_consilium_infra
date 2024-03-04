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

provider "kubernetes" {
  host                   = module.aks.kube_config.0.host
  username               = module.aks.kube_config.0.username
  password               = module.aks.kube_config.0.password
  client_certificate     = base64decode(module.aks.kube_config.0.client_certificate)
  client_key             = base64decode(module.aks.kube_config.0.client_key)
  cluster_ca_certificate = base64decode(module.aks.kube_config.0.cluster_ca_certificate)
}

provider "helm" {
  kubernetes {
    host                   = module.aks.kube_config.0.host
    client_certificate     = base64decode(module.aks.kube_config.0.client_certificate)
    client_key             = base64decode(module.aks.kube_config.0.client_key)
    cluster_ca_certificate = base64decode(module.aks.kube_config.0.cluster_ca_certificate)
  }
}

