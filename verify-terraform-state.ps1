# Terraform State Verification Script
# This script verifies that your Azure resources match the Terraform state in remote backend

Write-Host "🔍 Terraform State Verification Tool" -ForegroundColor Green
Write-Host "Checking consistency between Azure resources and Terraform state..." -ForegroundColor Yellow

# Configuration
$resourceGroup = "eShopCleverRG"
$storageAccount = "eshopterraformstate8636"
$container = "tfstate"
$subscriptionId = "5f62fee3-b00a-44d2-86e5-5cf130b28b5d"

Write-Host "`n📋 Configuration:" -ForegroundColor Cyan
Write-Host "  Resource Group: $resourceGroup"
Write-Host "  Storage Account: $storageAccount"
Write-Host "  State Container: $container"
Write-Host "  Subscription: $subscriptionId"

# Step 1: Verify we're in the right directory and backend is configured
Write-Host "`n🏗️ Step 1: Verifying Terraform Configuration..." -ForegroundColor Cyan

if (Test-Path "terraform-export-clean") {
    Set-Location "terraform-export-clean"
} else {
    Write-Host "❌ terraform-export-clean directory not found!" -ForegroundColor Red
    exit 1
}

# Check if backend.tf exists
if (Test-Path "backend.tf") {
    Write-Host "✅ backend.tf found" -ForegroundColor Green
    $backendContent = Get-Content "backend.tf" -Raw
    if ($backendContent -match $storageAccount) {
        Write-Host "✅ Backend configuration points to correct storage account" -ForegroundColor Green
    } else {
        Write-Host "❌ Backend configuration doesn't match expected storage account" -ForegroundColor Red
    }
} else {
    Write-Host "❌ backend.tf not found!" -ForegroundColor Red
}

# Step 2: Check remote state file exists
Write-Host "`n☁️ Step 2: Verifying Remote State File..." -ForegroundColor Cyan

Write-Host "Checking if state file exists in Azure Storage..." -ForegroundColor Gray
try {
    $stateFiles = az storage blob list --account-name $storageAccount --container-name $container --query '[].name' --output json --auth-mode login | ConvertFrom-Json
    
    if ($stateFiles -contains "terraform.tfstate") {
        Write-Host "✅ terraform.tfstate found in remote storage" -ForegroundColor Green
        
        # Get state file info
        $stateInfo = az storage blob show --account-name $storageAccount --container-name $container --name "terraform.tfstate" --auth-mode login | ConvertFrom-Json
        Write-Host "  📅 Last Modified: $($stateInfo.properties.lastModified)" -ForegroundColor Gray
        Write-Host "  📏 Size: $($stateInfo.properties.contentLength) bytes" -ForegroundColor Gray
    } else {
        Write-Host "❌ terraform.tfstate NOT found in remote storage" -ForegroundColor Red
        Write-Host "Available files: $($stateFiles -join ', ')" -ForegroundColor Yellow
    }
} catch {
    Write-Host "❌ Error accessing storage account: $($_.Exception.Message)" -ForegroundColor Red
}

# Step 3: Initialize Terraform with remote backend
Write-Host "`n🔄 Step 3: Initializing Terraform with Remote Backend..." -ForegroundColor Cyan
terraform init

# Step 4: Get resources from Terraform state
Write-Host "`n📊 Step 4: Retrieving Resources from Terraform State..." -ForegroundColor Cyan
$terraformResources = terraform state list

if ($terraformResources) {
    Write-Host "✅ Found $($terraformResources.Count) resources in Terraform state:" -ForegroundColor Green
    foreach ($resource in $terraformResources) {
        Write-Host "  📦 $resource" -ForegroundColor White
    }
} else {
    Write-Host "❌ No resources found in Terraform state!" -ForegroundColor Red
}

# Step 5: Get actual Azure resources in the resource group
Write-Host "`n🔍 Step 5: Retrieving Actual Azure Resources..." -ForegroundColor Cyan

$azureResources = az resource list --resource-group $resourceGroup --query '[].{name:name, type:type, id:id}' --output json | ConvertFrom-Json

if ($azureResources) {
    Write-Host "✅ Found $($azureResources.Count) resources in Azure Resource Group:" -ForegroundColor Green
    foreach ($resource in $azureResources) {
        Write-Host "  🔗 $($resource.name) ($($resource.type))" -ForegroundColor White
    }
} else {
    Write-Host "❌ No resources found in Azure Resource Group!" -ForegroundColor Red
}

# Step 6: Cross-reference and validate
Write-Host "`n🔄 Step 6: Cross-Referencing State vs Reality..." -ForegroundColor Cyan

# Create a mapping of expected resources
$expectedMapping = @{
    "azurerm_resource_group.eshop_rg" = "Microsoft.Resources/resourceGroups"
    "azurerm_container_registry.eshop_acr" = "Microsoft.ContainerRegistry/registries"
    "azurerm_kubernetes_cluster.eshop_aks" = "Microsoft.ContainerService/managedClusters"
    "azurerm_mssql_server.eshop_sql_server" = "Microsoft.Sql/servers"
    "azurerm_mssql_database.eshop_db" = "Microsoft.Sql/servers/databases"
    "azurerm_mssql_firewall_rule.allow_all" = "Microsoft.Sql/servers/firewallRules"
}

$validationResults = @()

foreach ($terraformResource in $terraformResources) {
    $expectedType = $expectedMapping[$terraformResource]
    
    if ($expectedType) {
        # Check if corresponding Azure resource exists
        $matchingAzureResource = $azureResources | Where-Object { $_.type -eq $expectedType }
        
        if ($matchingAzureResource) {
            $validationResults += @{
                TerraformResource = $terraformResource
                AzureResource = $matchingAzureResource.name
                Status = "✅ MATCHED"
                Type = $expectedType
            }
            Write-Host "  ✅ $terraformResource → $($matchingAzureResource.name)" -ForegroundColor Green
        } else {
            $validationResults += @{
                TerraformResource = $terraformResource
                AzureResource = "NOT FOUND"
                Status = "❌ MISSING"
                Type = $expectedType
            }
            Write-Host "  ❌ $terraformResource → NO MATCHING AZURE RESOURCE" -ForegroundColor Red
        }
    } else {
        Write-Host "  ⚠️ $terraformResource → UNKNOWN RESOURCE TYPE" -ForegroundColor Yellow
    }
}

# Step 7: Detailed resource verification
Write-Host "`n🔬 Step 7: Detailed Resource Verification..." -ForegroundColor Cyan

foreach ($terraformResource in $terraformResources) {
    Write-Host "`n📋 Checking $terraformResource..." -ForegroundColor Gray
    try {
        $resourceDetails = terraform state show $terraformResource
        
        # Extract resource ID from Terraform state
        $resourceIdLine = $resourceDetails | Where-Object { $_ -match "id\s*=" }
        if ($resourceIdLine) {
            $resourceId = ($resourceIdLine -split '=')[1].Trim().Trim('"')
            Write-Host "  🔗 State Resource ID: $resourceId" -ForegroundColor Gray
            
            # Check if this resource ID exists in Azure
            try {
                $azureResourceCheck = az resource show --ids $resourceId --output json 2>$null
                if ($azureResourceCheck) {
                    Write-Host "  ✅ Resource exists in Azure" -ForegroundColor Green
                } else {
                    Write-Host "  ❌ Resource NOT found in Azure" -ForegroundColor Red
                }
            } catch {
                Write-Host "  ❌ Error checking Azure resource: $($_.Exception.Message)" -ForegroundColor Red
            }
        }
    } catch {
        Write-Host "  ❌ Error getting state details: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Step 8: Summary Report
Write-Host "`n📊 VERIFICATION SUMMARY REPORT" -ForegroundColor Magenta
Write-Host "================================" -ForegroundColor Magenta

$matchedCount = ($validationResults | Where-Object { $_.Status -eq "✅ MATCHED" }).Count
$totalTerraformResources = $terraformResources.Count
$totalAzureResources = $azureResources.Count

Write-Host "`n📈 Statistics:" -ForegroundColor Yellow
Write-Host "  • Terraform State Resources: $totalTerraformResources"
Write-Host "  • Azure Resource Group Resources: $totalAzureResources"
Write-Host "  • Matched Resources: $matchedCount"
Write-Host "  • Match Percentage: $([math]::Round(($matchedCount / $totalTerraformResources) * 100, 2))%"

if ($matchedCount -eq $totalTerraformResources) {
    Write-Host "`n🎉 VERIFICATION SUCCESSFUL!" -ForegroundColor Green
    Write-Host "✅ All Terraform state resources match Azure resources" -ForegroundColor Green
    Write-Host "✅ Your state file is correctly synchronized" -ForegroundColor Green
} else {
    Write-Host "`n⚠️ VERIFICATION ISSUES FOUND!" -ForegroundColor Yellow
    Write-Host "❌ Some resources in Terraform state don't match Azure" -ForegroundColor Red
    Write-Host "🔧 Consider running: terraform refresh" -ForegroundColor Yellow
}

Write-Host "`n🔧 Next Steps:" -ForegroundColor Cyan
Write-Host "  1. If verification successful: Your state is correctly stored"
Write-Host "  2. If issues found: Run 'terraform refresh' to sync state"
Write-Host "  3. Always run 'terraform plan' before applying changes"
Write-Host "  4. Create backups with: .\manage-terraform-state.ps1 -Action backup"

Write-Host "`n🌐 Azure Portal Links:" -ForegroundColor Cyan
Write-Host "  • Resource Group: https://portal.azure.com/#@cleveritgroup.onmicrosoft.com/resource/subscriptions/$subscriptionId/resourceGroups/$resourceGroup"
Write-Host "  • Storage Account: https://portal.azure.com/#@cleveritgroup.onmicrosoft.com/resource/subscriptions/$subscriptionId/resourceGroups/$resourceGroup/providers/Microsoft.Storage/storageAccounts/$storageAccount"

# Return to original directory
Set-Location ..
