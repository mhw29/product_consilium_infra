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

output "host" {
    value = module.aks.kube_config.0.host

    sensitive = true
}

output "username" {
    value = module.aks.kube_config.0.username

    sensitive = true
}

output "password" {
    value = module.aks.kube_config.0.password

    sensitive = true
}

output "client_certificate" {
    value = base64decode(module.aks.kube_config.0.client_certificate)

    sensitive = true
}

output "client_key" {
    value = base64decode(module.aks.kube_config.0.client_key)

    sensitive = true
}

output "cluster_ca_certificate" {
    value = base64decode(module.aks.kube_config.0.cluster_ca_certificate)

    sensitive = true
}
