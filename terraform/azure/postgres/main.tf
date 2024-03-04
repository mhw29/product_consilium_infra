resource "azurerm_postgresql_server" "postgres_db" {
    name                          = var.postgres_dbname
    resource_group_name           = var.resource_group_name
    location                      = var.resource_group_location
    sku_name                      = "B_Gen5_1"
    storage_mb                    = 5120
    version                       = "11"
    administrator_login           = var.postgres_username
    administrator_login_password  = var.postgres_password
    ssl_enforcement_enabled       = true
}