# resource "azurerm_key_vault" "key_vault" {
#     name                        = "productconsiliumkv"
#     location                    = azurerm_resource_group.aks_rg.location
#     resource_group_name         = azurerm_resource_group.aks_rg.name
#     tenant_id                   = data.azurerm_client_config.current.tenant_id
#     sku_name                    = "standard"
#     enable_rbac_authorization   = true

#     soft_delete_retention_days  = 7
#     purge_protection_enabled    = false

#     network_acls {
#         default_action             = "Allow"
#         bypass                     = "AzureServices"
#     }
# }


resource "azurerm_key_vault" "current" {
  name                        = var.key_vault_display_name
  location                    = var.resource_group_location
  resource_group_name         = var.resource_group_name
  enabled_for_disk_encryption = true
  tenant_id                   = var.tenant_id
  soft_delete_retention_days  = 7
  purge_protection_enabled    = false

  sku_name = "standard"

  access_policy {
    tenant_id = var.tenant_id
    object_id = var.client_object_id

    key_permissions = [
      "Get",
      "List",
      "Create",
      "Delete",
      "Purge",
      "Decrypt",
      "Encrypt",
    ]

    secret_permissions = [
      "Set",
      "Get",
      "List",
      "Delete",
      "Purge",
      "Recover"
    ]

    storage_permissions = [
      "Set",
      "Get",
      "Delete",
      "Purge",
      "Recover"
    ]
  }

  access_policy {
    tenant_id = var.tenant_id
    object_id = var.eso_e2e_sp_object_id

    secret_permissions = [
      "Get",
      "Set",
      "Delete",
      "Purge",
      "Recover",
    ]

    key_permissions = [
      "Get",
      "List",
      "Create",
      "Delete",
      "Purge",
      "Decrypt",
      "Encrypt",
    ]

    certificate_permissions = [
      "Get",
      "List",
      "Create",
      "Delete",
      "Purge",
    ]
  }
}