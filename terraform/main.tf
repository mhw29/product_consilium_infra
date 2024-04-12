resource "azurerm_dns_zone" "current" {
    name                = "productconsilium.com"
    resource_group_name = azurerm_resource_group.current.name

    depends_on = [
        azurerm_resource_group.current
    ]
}

resource "azurerm_container_registry" "current" {
    name                     = "productconsilium"
    resource_group_name      = azurerm_resource_group.current.name
    location                 = azurerm_resource_group.current.location
    sku                      = "Standard"
    admin_enabled            = true

    depends_on = [
        azurerm_resource_group.current
    ]
}

data "azurerm_subscription" "primary" {}

data "azurerm_client_config" "current" {}

module "aks" {
    source                          = "./azure/aks"
    cluster_name                    = "productconsilium-aks"
    resource_group_location         = azurerm_resource_group.current.location
    resource_group_name             = azurerm_resource_group.current.name
    dns_prefix                      = "productconsilium"
    dns_zone_id                     = azurerm_dns_zone.current.id
    oidc_issuer_enabled             = true
    default_node_pool_name          = "default"
    default_node_pool_node_count    = 1
    default_node_pool_vm_size       = "Standard_B2s"
    cluster_tags                    = {}
    user_assigned_identity          = azurerm_user_assigned_identity.aks_identity.id

    depends_on = [
        azurerm_resource_group.current
    ]
}

module "workload-identity" {
    source      = "./azure/workload-identity"
    tenant_id   = data.azurerm_client_config.current.tenant_id
    tags        = {}

    depends_on = [
        module.aks
    ]
}

module "test_sp" {
  source = "./azure/service-principal"

  application_display_name = "test_sp_productconsilium"
  application_owners       = [data.azurerm_client_config.current.object_id]
  issuer                   = module.aks.cluster_issuer_url
  subject                  = "system:serviceaccount:${var.sa_namespace}:${var.sa_name}"

  depends_on = [
    azurerm_resource_group.current,
    module.aks
  ]
}


resource "kubernetes_namespace" "eso" {
  metadata {
    name = "external-secrets-operator"
  }

  depends_on = [
    module.aks
  ]
}

// the `e2e` pod itself runs with workload identity and
// does not rely on client credentials.
resource "kubernetes_service_account" "e2e" {
  metadata {
    name      = "external-secrets-e2e"
    namespace = "default"
    annotations = {
      "azure.workload.identity/client-id" = module.e2e_sp.application_id
      "azure.workload.identity/tenant-id" = data.azurerm_client_config.current.tenant_id
    }
    labels = {
      "azure.workload.identity/use" = "true"
    }
  }
  depends_on = [module.aks, kubernetes_namespace.eso]
}

resource "kubernetes_secret" "external_dns" {
  metadata {
    name      = "azure-config-file"
    namespace = kubernetes_namespace.product_consilium.metadata[0].name
  }
  data = {
    "azure.json" = jsonencode({
      tenantId                   = data.azurerm_client_config.current.tenant_id
      subscriptionId             = trimsuffix(trimprefix(data.azurerm_subscription.primary.id, "/subscriptions/"), "")
      resourceGroup              = azurerm_resource_group.current.name
      useManagedIdentityExtension = true
      userAssignedIdentityID     = module.aks.kubelet_identity_client_id
    })
  }
}

resource "azurerm_resource_group" "current" {
    name     = "product-consilium-resource-group"
    location = "centralus"
}

## Identity for kublet
resource "azurerm_user_assigned_identity" "aks_identity" {
  resource_group_name = azurerm_resource_group.current.name
  location            = azurerm_resource_group.current.location
  name                = "productconsilium-identity"
}

resource "azurerm_role_assignment" "aks_identity_acr" {
  scope                = azurerm_container_registry.current.id
  role_definition_name = "AcrPull"
  principal_id         = module.aks.kubelet_identity 
  depends_on = [
    azurerm_container_registry.current,
    module.aks
  ]
}

resource "azurerm_role_assignment" "aks_identity_kv" {
  scope                = module.key_vault.key_vault_id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = module.aks.kubelet_identity

  depends_on = [
    module.key_vault,
    module.aks
  ]
}

resource "azurerm_role_assignment" "aks_identity_dns" {
  scope                = azurerm_dns_zone.current.id
  role_definition_name = "DNS Zone Contributor"
  principal_id         = module.aks.kubelet_identity

  depends_on = [
    azurerm_dns_zone.current,
    module.aks
  ]
}


resource "kubernetes_namespace" "argo" {
  metadata {
    name = "argocd"
  }

  depends_on = [
    module.aks
  ]
}

resource "helm_release" "argocd" {
  name       = "argocd"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  version    = "6.6.0"

  namespace  = "argocd"

  values = [file("${path.module}/kubernetes/argocd/values.yaml")]

  # Ensure the namespace exists
  depends_on = [
    kubernetes_namespace.argo
  ]
}

resource "kubernetes_namespace" "product_consilium" {
  metadata {
    name = "productconsilium"
  }

  depends_on = [
    module.aks
  ]
}



##############SECRETS MANAGEMENT VIA EXTERNAL SECRETS##############
module "key_vault" {
    source = "./azure/key-vault"
    key_vault_display_name  = "productconsiliumkv"
    resource_group_location = azurerm_resource_group.current.location
    resource_group_name     = azurerm_resource_group.current.name
    tenant_id               = data.azurerm_client_config.current.tenant_id
    client_object_id        = module.aks.kubelet_identity
    eso_e2e_sp_object_id    = module.e2e_sp.sp_object_id

    depends_on = [
        azurerm_resource_group.current,
        module.e2e_sp
    ]
}

module "e2e_sp" {
  source = "./azure/service-principal"

  application_display_name = "e2e_sp_productconsilium"
  application_owners       = [data.azurerm_client_config.current.object_id]
  issuer                   = module.aks.cluster_issuer_url
  subject                  = "system:serviceaccount:default:external-secrets-e2e"

  depends_on = [
    azurerm_resource_group.current,
    module.aks
  ]
}

resource "azurerm_role_assignment" "eso_key_vault_secrets_user" {
  scope                = module.key_vault.key_vault_id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = module.e2e_sp.sp_id

  depends_on = [
    module.key_vault,
    module.aks
  ]
}

resource "helm_release" "external_secrets" {
  name       = "external-secrets"
  repository = "https://charts.external-secrets.io"
  chart      = "external-secrets"
  namespace  = "external-secrets"
  create_namespace = true

  depends_on = [
    module.key_vault,
    module.aks
  ]

}

#Cert Manager
resource "helm_release" "cert_manager" {
  name       = "cert-manager"
  repository = "https://charts.jetstack.io"
  chart      = "cert-manager"
  version    = "v1.14.4"
  namespace  = "cert-manager"
  create_namespace = true
  set {
      name  = "installCRDs"
      value = "true"
    }
    
  depends_on = [
    module.aks
  ]
}
resource "kubernetes_secret" "azure-secret-sp" {
  metadata {
    name      = "azure-secret-sp"
    namespace = kubernetes_namespace.product_consilium.metadata[0].name
  }

  data = {
    ClientID     = module.e2e_sp.application_id
    ClientSecret = module.e2e_sp.sp_password
  }
}

resource "kubernetes_manifest" "secret_store" {
  provider = kubernetes

  manifest = {
    apiVersion = "external-secrets.io/v1alpha1"
    kind       = "SecretStore"
    metadata = {
      name      = "azure-backend"
      namespace = kubernetes_namespace.product_consilium.metadata[0].name
    }
    spec = {
      provider = {
        azurekv = {
          tenantId  = data.azurerm_client_config.current.tenant_id
          vaultUrl  = module.key_vault.key_vault_uri
          authSecretRef = {
            clientId = {
              name = kubernetes_secret.azure-secret-sp.metadata[0].name
              key  = "ClientID"
            }
            clientSecret = {
              name = kubernetes_secret.azure-secret-sp.metadata[0].name
              key  = "ClientSecret"
            }
          }
        }
      }
    }
  }

  depends_on = [
    module.key_vault,
    module.aks,
    kubernetes_namespace.product_consilium
  ]
}

resource "kubernetes_manifest" "product_consilium_argocd_application" {
  provider = kubernetes

  manifest = {
    apiVersion = "argoproj.io/v1alpha1"
    kind       = "Application"
    metadata = {
      name      = "productconsilium"
      namespace = "argocd"
    }
    spec = {
      project = "default"

      source = {
        repoURL        = "https://github.com/mhw29/product_consilium_infra.git"
        targetRevision = "HEAD"
        path           = "kubernetes/overlays/dev"
      }

      destination = {
        server    = "https://kubernetes.default.svc"
        namespace = "productconsilium"
      }

      syncPolicy = {
        automated = {
          prune      = true
          selfHeal   = true
        }
      }
    }
  }
  depends_on = [
    module.key_vault,
    module.aks,
    kubernetes_namespace.product_consilium
  ]
}



