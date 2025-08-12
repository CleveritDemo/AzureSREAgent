# Quick Migration Configuration Script
# This script helps configure the new environment variables for migration

param(
    [Parameter(Mandatory=$true)]
    [string]$NewTenantId,
    
    [Parameter(Mandatory=$true)]
    [string]$NewSubscriptionId,
    
    [Parameter(Mandatory=$true)]
    [string]$NewClientId,
    
    [string]$NewRegion = "East US"
)

Write-Host "🔧 Azure Infrastructure Migration Configuration" -ForegroundColor Blue
Write-Host "=============================================" -ForegroundColor Blue

# Create new environment configuration
$newConfig = @"
# New Environment Configuration
# Generated on $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')

# Azure Authentication
AZURE_TENANT_ID="$NewTenantId"
AZURE_SUBSCRIPTION_ID="$NewSubscriptionId" 
AZURE_CLIENT_ID="$NewClientId"

# Infrastructure Settings
AZURE_REGION="$NewRegion"
RESOURCE_GROUP_NAME="eShopCleverRG"
PROJECT_NAME="eshopclever"

# Resource Names (keeping same names)
AKS_CLUSTER_NAME="eshopcleveraks"
ACR_NAME="eshopcleveracr"
SQL_SERVER_NAME="eshopclever-sqlsrv"
SQL_DATABASE_NAME="eshopdb"
"@

# Save configuration
$configFile = "new-environment-config.env"
$newConfig | Out-File $configFile -Encoding UTF8

Write-Host "✅ Configuration saved to: $configFile" -ForegroundColor Green

# Create Terraform variables
$tfVarsContent = @"
# Terraform Variables for New Environment
tenant_id = "$NewTenantId"
subscription_id = "$NewSubscriptionId"
resource_group_name = "eShopCleverRG"
resource_group_location = "$NewRegion"
project_name = "eshopclever"
environment = "production"
# sql_admin_password = "YOUR_SECURE_PASSWORD_HERE"
"@

$tfVarsFile = "new-environment.tfvars"
$tfVarsContent | Out-File $tfVarsFile -Encoding UTF8

Write-Host "✅ Terraform variables saved to: $tfVarsFile" -ForegroundColor Green

# Display GitHub Secrets to update
Write-Host ""
Write-Host "🔐 GitHub Secrets to Update:" -ForegroundColor Yellow
Write-Host "AZURE_CLIENT_ID=$NewClientId"
Write-Host "AZURE_TENANT_ID=$NewTenantId"
Write-Host "AZURE_SUBSCRIPTION_ID=$NewSubscriptionId"

Write-Host ""
Write-Host "📋 Next Steps:" -ForegroundColor Blue
Write-Host "1. Review and update the generated configuration files"
Write-Host "2. Set SQL admin password in $tfVarsFile"
Write-Host "3. Create Service Principal in new tenant with Contributor role"
Write-Host "4. Update GitHub repository secrets"
Write-Host "5. Run migration validation script"
Write-Host "6. Execute Terraform deployment to new environment"
