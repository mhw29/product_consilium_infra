# resource "kubernetes_namespace" "argocd" {
#   metadata {
#     name = "argocd"
#   }
# }

# resource "helm_release" "argocd" {
#   name       = "argocd"
#   chart      = "argo-cd"
#   repository = "https://argoproj.github.io/argo-helm"
#   version    = "5.27.3"
#   namespace  = "argocd"
#   timeout    = "1200"
#   values     = [templatefile("./kubernetes/argocd/values.yaml", {})]
# }

# resource "kubernetes_manifest" "namespace" {
#   depends_on = [helm_release.argocd]
#   manifest = yamldecode(templatefile("./kubernetes/argocd/namespace.yaml", {}))
# }
# resource "kubernetes_manifest" "application" {
#   depends_on = [kubernetes_manifest.namespace]
#   manifest = yamldecode(templatefile("./kubernetes/argocd/application.yaml", {}))
# }





