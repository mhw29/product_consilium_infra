resource "azurerm_postgresql_server" "postgres_db" {
    name                          = "productconsilium-postgres"
    location                      = azurerm_resource_group.aks_rg.location
    resource_group_name           = azurerm_resource_group.aks_rg.name
    sku_name                      = "B_Gen5_1"
    storage_mb                    = 5120
    version                       = "11"
    administrator_login           = var.postgres_username
    administrator_login_password  = var.postgres_password
    ssl_enforcement_enabled       = true
}