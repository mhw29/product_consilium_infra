provider "kubernetes" {
  host                   = var.host
  username               = var.username
  password               = var.password
  client_certificate     = var.client_certificate
  client_key             = var.client_key
  cluster_ca_certificate = var.cluster_ca_certificate
}

provider "helm" {
  kubernetes {
    host                   = var.host 
    client_certificate     = var.client_certificate
    client_key             = var.client_key
    cluster_ca_certificate = var.cluster_ca_certificate
  }
}

resource "kubernetes_namespace" "argocd" {
  depends_on = [data.azurerm_kubernetes_cluster.main]

  metadata {
    name = "argocd"
  }
}