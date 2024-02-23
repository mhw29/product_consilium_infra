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
  metadata {
    name = "argocd"
  }
}

resource "helm_release" "argocd-staging" {
  name       = "argocd-staging"
  chart      = "argo-cd"
  repository = "https://argoproj.github.io/argo-helm"
  version    = "5.27.3"
  namespace  = "argocd"
  timeout    = "1200"
  values     = [templatefile("./kubernetes_module/argocd/values.yaml", {})]
}


