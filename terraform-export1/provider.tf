provider "azurerm" {
  features {
  }
  subscription_id                 = "cab7669e-f28b-4420-8e9d-c8ad1634ce44"
  environment                     = "public"
  use_msi                         = false
  use_cli                         = true
  use_oidc                        = false
  resource_provider_registrations = "none"
}
