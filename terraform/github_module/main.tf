provider "github" {
  token        = var.github_token
  owner        = var.github_owner
}

resource "github_actions_secret" "sp_id" {
  repository      = var.github_repository
  secret_name     = "AZURE_SERVICE_PRINCIPAL_ID"
  plaintext_value = azuread_service_principal.sp.application_id
}

resource "github_actions_secret" "sp_secret" {
  repository      = var.github_repository
  secret_name     = "AZURE_SERVICE_PRINCIPAL_SECRET"
  plaintext_value = azuread_service_principal_password.sp_password.value
}

resource "github_actions_secret" "tenant_id" {
  repository      = var.github_repository
  secret_name     = "AZURE_TENANT_ID"
  plaintext_value = data.azuread_client_config.current.tenant_id
}

