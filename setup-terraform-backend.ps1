# Azure Storage Account Setup for Terraform Backend
# This script creates and configures a storage account for Terraform state management

Write-Host "🏗️ Setting up Azure Storage Account for Terraform Backend" -ForegroundColor Green

# Configuration
$resourceGroup = "eShopCleverRG"
$storageAccountName = "eshopterraformstate$(Get-Random -Minimum 1000 -Maximum 9999)"
$containerName = "tfstate"
$location = "East US"
$subscriptionId = "5f62fee3-b00a-44d2-86e5-5cf130b28b5d"

Write-Host "📋 Configuration:" -ForegroundColor Yellow
Write-Host "  Resource Group: $resourceGroup"
Write-Host "  Storage Account: $storageAccountName"
Write-Host "  Container: $containerName" 
Write-Host "  Location: $location"
Write-Host "  Subscription: $subscriptionId"

# Step 1: Create Storage Account
Write-Host "`n🔧 Step 1: Creating Storage Account..." -ForegroundColor Cyan
az storage account create `
    --name $storageAccountName `
    --resource-group $resourceGroup `
    --location $location `
    --sku Standard_LRS `
    --encryption-services blob `
    --https-only true `
    --min-tls-version TLS1_2 `
    --allow-blob-public-access false

# Step 2: Get Storage Account Key
Write-Host "`n🔑 Step 2: Getting Storage Account Key..." -ForegroundColor Cyan
$accountKey = az storage account keys list `
    --resource-group $resourceGroup `
    --account-name $storageAccountName `
    --query '[0].value' `
    --output tsv

# Step 3: Create Blob Container
Write-Host "`n📦 Step 3: Creating Blob Container..." -ForegroundColor Cyan
az storage container create `
    --name $containerName `
    --account-name $storageAccountName `
    --account-key $accountKey `
    --public-access off

# Step 4: Enable versioning and soft delete
Write-Host "`n🛡️ Step 4: Enabling versioning and soft delete..." -ForegroundColor Cyan
az storage account blob-service-properties update `
    --account-name $storageAccountName `
    --resource-group $resourceGroup `
    --enable-versioning true `
    --enable-delete-retention true `
    --delete-retention-days 30

# Step 5: Create backend configuration file
Write-Host "`n📄 Step 5: Creating backend configuration..." -ForegroundColor Cyan

$backendConfig = @"
terraform {
  backend "azurerm" {
    resource_group_name  = "$resourceGroup"
    storage_account_name = "$storageAccountName"
    container_name       = "$containerName"
    key                  = "terraform.tfstate"
  }
}
"@

# Save to terraform backend file
$backendConfig | Out-File -FilePath "terraform-export-clean/backend.tf" -Encoding UTF8

# Step 6: Create environment-specific backend configs
Write-Host "`n🌍 Step 6: Creating environment-specific configs..." -ForegroundColor Cyan

# Development backend
$devBackend = @"
resource_group_name  = "$resourceGroup"
storage_account_name = "$storageAccountName"
container_name       = "$containerName"
key                  = "dev/terraform.tfstate"
"@
$devBackend | Out-File -FilePath "terraform-export-clean/backend-dev.conf" -Encoding UTF8

# Production backend
$prodBackend = @"
resource_group_name  = "$resourceGroup"
storage_account_name = "$storageAccountName"
container_name       = "$containerName"  
key                  = "prod/terraform.tfstate"
"@
$prodBackend | Out-File -FilePath "terraform-export-clean/backend-prod.conf" -Encoding UTF8

# Test backend
$testBackend = @"
resource_group_name  = "$resourceGroup"
storage_account_name = "$storageAccountName"
container_name       = "$containerName"
key                  = "test/terraform.tfstate"
"@
$testBackend | Out-File -FilePath "terraform-export-clean/backend-test.conf" -Encoding UTF8

# Step 7: Create deployment script
Write-Host "`n🚀 Step 7: Creating deployment scripts..." -ForegroundColor Cyan

$deployScript = @"
# Terraform Deployment Script with Remote Backend
param(
    [Parameter(Mandatory=`$false)]
    [ValidateSet("dev", "test", "prod")]
    [string]`$Environment = "dev"
)

Write-Host "🚀 Deploying Terraform with Environment: `$Environment" -ForegroundColor Green

# Initialize with backend
terraform init -backend-config="backend-`$Environment.conf"

# Validate configuration
terraform validate

# Plan deployment
terraform plan -var-file="`$Environment.tfvars" -out="terraform.tfplan"

# Apply if user confirms
`$confirmation = Read-Host "Do you want to apply this plan? (y/N)"
if (`$confirmation -eq 'y' -or `$confirmation -eq 'Y') {
    terraform apply "terraform.tfplan"
    
    Write-Host "`n✅ Deployment completed!" -ForegroundColor Green
    Write-Host "🌐 Azure Portal: https://portal.azure.com/#@cleveritgroup.onmicrosoft.com/resource/subscriptions/$subscriptionId/resourceGroups/$resourceGroup" -ForegroundColor Cyan
} else {
    Write-Host "❌ Deployment cancelled" -ForegroundColor Yellow
}
"@

$deployScript | Out-File -FilePath "terraform-export-clean/deploy-with-backend.ps1" -Encoding UTF8

# Step 8: Output configuration details
Write-Host "`n✅ Setup Complete!" -ForegroundColor Green
Write-Host "`n📋 Backend Configuration:" -ForegroundColor Yellow
Write-Host "  Storage Account: $storageAccountName"
Write-Host "  Resource Group: $resourceGroup"
Write-Host "  Container: $containerName"
Write-Host "  Account Key: $($accountKey.Substring(0,8))..." -ForegroundColor Gray

Write-Host "`n📁 Files Created:" -ForegroundColor Yellow
Write-Host "  ✓ backend.tf - Main backend configuration"
Write-Host "  ✓ backend-dev.conf - Development environment config"
Write-Host "  ✓ backend-test.conf - Test environment config" 
Write-Host "  ✓ backend-prod.conf - Production environment config"
Write-Host "  ✓ deploy-with-backend.ps1 - Deployment script"

Write-Host "`n🔧 Next Steps:" -ForegroundColor Cyan
Write-Host "  1. cd terraform-export-clean"
Write-Host "  2. .\deploy-with-backend.ps1 -Environment dev"
Write-Host "  3. Your Terraform state will be stored remotely!"

Write-Host "`n🌐 Storage Account Portal:" -ForegroundColor Cyan
Write-Host "  https://portal.azure.com/#@cleveritgroup.onmicrosoft.com/resource/subscriptions/$subscriptionId/resourceGroups/$resourceGroup/providers/Microsoft.Storage/storageAccounts/$storageAccountName"
