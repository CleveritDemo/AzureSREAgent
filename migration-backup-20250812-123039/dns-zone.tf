# Add DNS Zone and Custom Domain resources to Terraform configuration

# DNS Zone for custom domain (only created when enabled)
resource "azurerm_dns_zone" "eshop_domain" {
  count               = var.enable_custom_domain ? 1 : 0
  name                = var.custom_domain_name
  resource_group_name = azurerm_resource_group.eshop_rg.name
  
  tags = {
    project     = var.project_name
    environment = var.environment
    purpose     = "custom-domain"
  }
}

# A record for root domain pointing to ingress IP
resource "azurerm_dns_a_record" "eshop_root" {
  count               = var.enable_custom_domain ? 1 : 0
  name                = "@"
  zone_name           = azurerm_dns_zone.eshop_domain[0].name
  resource_group_name = azurerm_resource_group.eshop_rg.name
  ttl                 = 300
  records             = [var.ingress_ip_address]
  
  tags = {
    project     = var.project_name
    environment = var.environment
  }
  
  depends_on = [azurerm_dns_zone.eshop_domain]
}

# A record for www subdomain
resource "azurerm_dns_a_record" "eshop_www" {
  count               = var.enable_custom_domain ? 1 : 0
  name                = "www"
  zone_name           = azurerm_dns_zone.eshop_domain[0].name
  resource_group_name = azurerm_resource_group.eshop_rg.name
  ttl                 = 300
  records             = [var.ingress_ip_address]
  
  tags = {
    project     = var.project_name
    environment = var.environment
  }
  
  depends_on = [azurerm_dns_zone.eshop_domain]
}

# A record for staging subdomain
resource "azurerm_dns_a_record" "eshop_staging" {
  count               = var.enable_custom_domain ? 1 : 0
  name                = "staging"
  zone_name           = azurerm_dns_zone.eshop_domain[0].name
  resource_group_name = azurerm_resource_group.eshop_rg.name
  ttl                 = 300
  records             = [var.ingress_ip_address]
  
  tags = {
    project     = var.project_name
    environment = var.environment
  }
  
  depends_on = [azurerm_dns_zone.eshop_domain]
}

# CNAME record for API subdomain (optional)
resource "azurerm_dns_cname_record" "eshop_api" {
  count               = var.enable_custom_domain ? 1 : 0
  name                = "api"
  zone_name           = azurerm_dns_zone.eshop_domain[0].name
  resource_group_name = azurerm_resource_group.eshop_rg.name
  ttl                 = 300
  record              = var.custom_domain_name
  
  tags = {
    project     = var.project_name
    environment = var.environment
  }
  
  depends_on = [azurerm_dns_zone.eshop_domain]
}

# TXT record for domain verification (if needed)
resource "azurerm_dns_txt_record" "eshop_verification" {
  count               = var.enable_custom_domain ? 1 : 0
  name                = "@"
  zone_name           = azurerm_dns_zone.eshop_domain[0].name
  resource_group_name = azurerm_resource_group.eshop_rg.name
  ttl                 = 300
  
  record {
    value = "v=spf1 -all"  # SPF record to prevent email spoofing
  }
  
  record {
    value = "eshopclever-domain-verification-${random_string.domain_verification.result}"
  }
  
  tags = {
    project     = var.project_name
    environment = var.environment
  }
  
  depends_on = [azurerm_dns_zone.eshop_domain]
}

# Random string for domain verification
resource "random_string" "domain_verification" {
  length  = 32
  special = false
  upper   = false
}

# Output the name servers for domain registrar configuration
output "dns_name_servers" {
  description = "Name servers to configure at your domain registrar"
  value       = var.enable_custom_domain ? azurerm_dns_zone.eshop_domain[0].name_servers : []
}

output "custom_domain_name" {
  description = "The configured custom domain name"
  value       = var.enable_custom_domain ? azurerm_dns_zone.eshop_domain[0].name : "Not configured"
}

output "domain_verification_txt" {
  description = "Domain verification TXT record value"
  value       = "eshopclever-domain-verification-${random_string.domain_verification.result}"
}

output "dns_zone_id" {
  description = "The Azure DNS Zone resource ID"
  value       = var.enable_custom_domain ? azurerm_dns_zone.eshop_domain[0].id : null
}
