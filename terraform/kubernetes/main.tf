

resource "kubernetes_namespace" "argocd" {
  metadata {
    name = "argocd"
  }
}

resource "kubernetes_secret" "example" {
  metadata {
    name = "example-secret"
  }

  data = {
    "password" = base64encode("mySuperSecretPassword")
  }
}

resource "helm_release" "argocd" {
  name       = "argocd"
  chart      = "argo-cd"
  repository = "https://argoproj.github.io/argo-helm"
  version    = "5.27.3"
  namespace  = "argocd"
  timeout    = "1200"
  values     = [templatefile("./kubernetes/argocd/values.yaml", {})]
}

resource "kubernetes_manifest" "namespace" {
  depends_on = [helm_release.argocd]
  manifest = yamldecode(templatefile("./kubernetes/argocd/namespace.yaml", {}))
}
resource "kubernetes_manifest" "application" {
  depends_on = [kubernetes_manifest.namespace]
  manifest = yamldecode(templatefile("./kubernetes/argocd/application.yaml", {}))
}

## External Secrets
# resource "helm_release" "external-secrets" {
#   name       = "external-secrets"
#   chart      = "external-secrets"
#   repository = "https://charts.external-secrets.io"
#   version    = "0.9.13"
#   values     = [templatefile("./kubernetes_module/external-secrets/values.yaml", {})]
# }





