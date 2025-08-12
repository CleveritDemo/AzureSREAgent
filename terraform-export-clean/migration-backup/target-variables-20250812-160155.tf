# Deployment Configuration
variable "subscription_id" {
  description = "Azure subscription ID where resources will be created"
  type        = string
  default     = "5f62fee3-b00a-44d2-86e5-5cf130b28b5d"  # Current subscription - will be overridden for migration
}

variable "tenant_id" {
  description = "Azure tenant ID where the subscription belongs"
  type        = string
  default     = "1033d128-85ad-47b4-8c85-0a28b6ce0297"  # Current tenant - will be overridden for migration
}

variable "resource_group_name" {
  description = "Name of the resource group to create or use"
  type        = string
  default     = "eShopCleverRG"  # Your current RG
}

variable "resource_group_location" {
  description = "Location for the resource group"
  type        = string
  default     = "East US 2"
}

# Resource Configuration
variable "project_name" {
  description = "Name prefix for all resources"
  type        = string
  default     = "eshopclever"
}

variable "environment" {
  description = "Environment tag (dev, staging, prod, demo)"
  type        = string
  default     = "demo"
}

# Security Configuration
variable "sql_admin_password" {
  description = "Password for the SQL Server administrator"
  type        = string
  sensitive   = true
  default     = "_Matilde11"  # Your current password
}

variable "ssh_public_key" {
  description = "SSH public key for AKS nodes"
  type        = string
  default     = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC33ECCPzwTwcnPvlI/ivFIgINIleg8Yxxe8aNHek5fpgr0dVfkNgmIYqP4F7Je9hBsdlIP1EFC/OU7Mepele4dSlEY4DJmSDQUH4BhAN+fGhKmt1k847dZezP0KGSli8LqdvWL3k2s3WsSPkEg4AD1A5jqDsKBUPN60giMJxT0tDvMuo59kVleJWR05NfzshKWvDuBLBaGmsRLcNBY+EnJcNHVU/ufMDifYq9HUOPd5PxTsprlU0uy5MDp0GvYEqhu/cIW48tF8AfIXfDjiI4vlXje2KtJhlZfehQ0FaMUkJPk/1yZqXbNxm5YRwwCOIeUkBLLkZUu+3Yt7KK2YBjR"
}

# Custom Domain Configuration
variable "custom_domain_name" {
  description = "Custom domain name for the application (e.g., eshopclever.com)"
  type        = string
  default     = "eshopclever.com"
}

variable "ingress_ip_address" {
  description = "IP address of the ingress controller load balancer (set after ingress deployment)"
  type        = string
  default     = "0.0.0.0"  # Will be updated after ingress controller deployment
}

variable "enable_custom_domain" {
  description = "Whether to create Azure DNS zone and records for custom domain"
  type        = bool
  default     = false  # Set to true when ready to configure custom domain
}
