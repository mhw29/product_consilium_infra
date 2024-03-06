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

# module "kubernetes" {
#     source = "./kubernetes"
#     host                   = module.aks.host
#     username               = module.aks.username
#     password               = module.aks.password
#     client_certificate     = module.aks.client_certificate
#     client_key             = module.aks.client_key
#     cluster_ca_certificate = module.aks.cluster_ca_certificate
# }
# resource "kubernetes_namespace" "argocd" {
#   metadata {
#     name = "argocd"
#   }
# }

module "aks" {
    source                          = "./azure/aks"
    cluster_name                    = "productconsilium-aks"
    resource_group_location         = azurerm_resource_group.current.location
    resource_group_name             = azurerm_resource_group.current.name
    dns_prefix                      = "productconsilium"
    oidc_issuer_enabled             = true
    default_node_pool_name          = "default"
    default_node_pool_node_count    = 1
    default_node_pool_vm_size       = "Standard_B2s"
    cluster_tags                    = {}

    depends_on = [
        azurerm_resource_group.current
    ]
}

module "key_vault" {
    source = "./azure/key-vault"
    key_vault_display_name  = "productconsiliumkv"
    resource_group_location = azurerm_resource_group.current.location
    resource_group_name     = azurerm_resource_group.current.name
    tenant_id               = data.azurerm_client_config.current.tenant_id
    client_object_id        = data.azurerm_client_config.current.object_id
    eso_e2e_sp_object_id    = module.e2e_sp.sp_object_id

    depends_on = [
        azurerm_resource_group.current,
        module.e2e_sp
    ]
}

module "workload-identity" {
    source      = "./azure/workload-identity"
    tenant_id   = data.azurerm_client_config.current.tenant_id
    tags        = {}
}

module "postgres" {
    source                  = "./azure/postgres"
    postgres_dbname         = "productconsilium-postgres"
    postgres_username       = var.postgres_username
    postgres_password       = var.postgres_password
    resource_group_location = azurerm_resource_group.current.location
    resource_group_name     = azurerm_resource_group.current.name
    
    depends_on = [
        azurerm_resource_group.current
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

# resource "azurerm_role_assignment" "current" {
#   scope                = data.azurerm_subscription.primary.id
#   role_definition_name = "Key Vault Secrets User"
#   principal_id         = module.test_sp.sp_id

#   depends_on = [
#     azurerm_resource_group.current,
#     module.test_sp
#   ]
# }
resource "kubernetes_namespace" "eso" {
  metadata {
    name = "external-secrets-operator"
  }
}

// the `e2e` pod itself runs with workload identity and
// does not rely on client credentials.
# resource "kubernetes_service_account" "e2e" {
#   metadata {
#     name      = "external-secrets-e2e"
#     namespace = "default"
#     annotations = {
#       "azure.workload.identity/client-id" = module.e2e_sp.application_id
#       "azure.workload.identity/tenant-id" = data.azurerm_client_config.current.tenant_id
#     }
#     labels = {
#       "azure.workload.identity/use" = "true"
#     }
#   }
#   depends_on = [module.aks, kubernetes_namespace.eso]
# }

# resource "kubernetes_service_account" "current" {
#   metadata {
#     name      = "external-secrets-operator"
#     namespace = "external-secrets-operator"
#     annotations = {
#       "azure.workload.identity/client-id" = module.test_sp.application_id
#       "azure.workload.identity/tenant-id" = data.azurerm_client_config.current.tenant_id
#     }
#     labels = {
#       "azure.workload.identity/use" = "true"
#     }
#   }
#   depends_on = [module.aks, kubernetes_namespace.eso]
# }
resource "azurerm_resource_group" "current" {
    name     = "product-consilium-resource-group"
    location = "centralus"
}

resource "azurerm_role_assignment" "key_vault_secrets_user" {
  scope                = module.key_vault.key_vault_id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = module.aks.principal_id

  depends_on = [
    module.key_vault,
    module.aks
  ]
}

resource "kubernetes_namespace" "argo" {
  metadata {
    name = "argocd"
  }
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
}



