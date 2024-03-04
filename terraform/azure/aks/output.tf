output "cluster_issuer_url" {
  value = azurerm_kubernetes_cluster.current.oidc_issuer_url
}

output "kube_config" {
  value = azurerm_kubernetes_cluster.current.kube_config_raw

  sensitive = true
}

output "principal_id" {
  value = azurerm_kubernetes_cluster.current.identity[0].principal_id
}