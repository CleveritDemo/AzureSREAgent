# Terraform State Management Script
# This script helps manage Terraform states across different environments

param(
    [Parameter(Mandatory=$false)]
    [ValidateSet("dev", "test", "prod", "list", "show", "backup")]
    [string]$Action = "list",
    
    [Parameter(Mandatory=$false)]
    [string]$ResourceName = ""
)

Write-Host "🗂️ Terraform State Management Tool" -ForegroundColor Green

switch ($Action) {
    "list" {
        Write-Host "`n📋 Listing all resources in current state..." -ForegroundColor Cyan
        terraform state list
    }
    
    "show" {
        if ($ResourceName) {
            Write-Host "`n🔍 Showing details for resource: $ResourceName" -ForegroundColor Cyan
            terraform state show $ResourceName
        } else {
            Write-Host "❌ Please provide -ResourceName parameter" -ForegroundColor Red
            Write-Host "Usage: .\manage-terraform-state.ps1 -Action show -ResourceName 'azurerm_resource_group.eshop_rg'" -ForegroundColor Yellow
        }
    }
    
    "backup" {
        Write-Host "`n💾 Creating state backup..." -ForegroundColor Cyan
        $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
        $backupPath = "terraform-backup-$timestamp.tfstate"
        terraform state pull > $backupPath
        Write-Host "✅ State backed up to: $backupPath" -ForegroundColor Green
    }
    
    "dev" {
        Write-Host "`n🔄 Switching to development environment..." -ForegroundColor Cyan
        terraform init -backend-config="backend-dev.conf" -reconfigure
        Write-Host "✅ Switched to dev environment" -ForegroundColor Green
    }
    
    "test" {
        Write-Host "`n🔄 Switching to test environment..." -ForegroundColor Cyan
        terraform init -backend-config="backend-test.conf" -reconfigure
        Write-Host "✅ Switched to test environment" -ForegroundColor Green
    }
    
    "prod" {
        Write-Host "`n🔄 Switching to production environment..." -ForegroundColor Cyan
        terraform init -backend-config="backend-prod.conf" -reconfigure
        Write-Host "✅ Switched to production environment" -ForegroundColor Green
    }
}

Write-Host "`n📊 Current Backend Configuration:" -ForegroundColor Yellow
if (Test-Path ".terraform/terraform.tfstate") {
    $config = Get-Content ".terraform/terraform.tfstate" | ConvertFrom-Json
    if ($config.backend.config) {
        Write-Host "  Storage Account: $($config.backend.config.storage_account_name)" -ForegroundColor White
        Write-Host "  Container: $($config.backend.config.container_name)" -ForegroundColor White
        Write-Host "  State Key: $($config.backend.config.key)" -ForegroundColor White
    }
}

Write-Host "`n🔧 Available Commands:" -ForegroundColor Cyan
Write-Host "  .\manage-terraform-state.ps1 -Action list" -ForegroundColor White
Write-Host "  .\manage-terraform-state.ps1 -Action show -ResourceName 'resource_name'" -ForegroundColor White
Write-Host "  .\manage-terraform-state.ps1 -Action backup" -ForegroundColor White
Write-Host "  .\manage-terraform-state.ps1 -Action dev" -ForegroundColor White
Write-Host "  .\manage-terraform-state.ps1 -Action test" -ForegroundColor White
Write-Host "  .\manage-terraform-state.ps1 -Action prod" -ForegroundColor White
