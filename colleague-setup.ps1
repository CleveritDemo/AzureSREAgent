# Colleague Quick Setup Script for Terraform Remote State
# Run this script to automatically configure your environment for shared Terraform state

Write-Host "🚀 eShopOnWeb Terraform Environment Setup" -ForegroundColor Green
Write-Host "Setting up shared remote state access..." -ForegroundColor Yellow

# Configuration
$subscriptionId = "5f62fee3-b00a-44d2-86e5-5cf130b28b5d"
$resourceGroup = "eShopCleverRG"
$storageAccount = "eshopterraformstate8636"

Write-Host "`n📋 Configuration:" -ForegroundColor Cyan
Write-Host "  Subscription: $subscriptionId"
Write-Host "  Resource Group: $resourceGroup"
Write-Host "  Storage Account: $storageAccount"

# Step 1: Check prerequisites
Write-Host "`n🔍 Step 1: Checking Prerequisites..." -ForegroundColor Cyan

# Check Azure CLI
try {
    $azVersion = az version --output json | ConvertFrom-Json
    Write-Host "  ✅ Azure CLI: $($azVersion.'azure-cli')" -ForegroundColor Green
} catch {
    Write-Host "  ❌ Azure CLI not found! Please install Azure CLI first." -ForegroundColor Red
    Write-Host "     Download from: https://docs.microsoft.com/en-us/cli/azure/install-azure-cli" -ForegroundColor Yellow
    exit 1
}

# Check Terraform
try {
    $tfVersion = terraform version -json | ConvertFrom-Json
    Write-Host "  ✅ Terraform: $($tfVersion.terraform_version)" -ForegroundColor Green
} catch {
    Write-Host "  ❌ Terraform not found! Please install Terraform first." -ForegroundColor Red
    Write-Host "     Download from: https://www.terraform.io/downloads" -ForegroundColor Yellow
    exit 1
}

# Step 2: Azure Authentication
Write-Host "`n🔐 Step 2: Azure Authentication..." -ForegroundColor Cyan

$currentAccount = az account show --output json 2>$null
if ($LASTEXITCODE -ne 0) {
    Write-Host "  🔑 Please login to Azure..." -ForegroundColor Yellow
    az login
    if ($LASTEXITCODE -ne 0) {
        Write-Host "  ❌ Azure login failed!" -ForegroundColor Red
        exit 1
    }
}

# Set correct subscription
Write-Host "  🎯 Setting subscription..." -ForegroundColor Gray
az account set --subscription $subscriptionId
if ($LASTEXITCODE -eq 0) {
    Write-Host "  ✅ Subscription set successfully" -ForegroundColor Green
} else {
    Write-Host "  ❌ Failed to set subscription. Check your access permissions." -ForegroundColor Red
    exit 1
}

# Verify access to resource group
Write-Host "  🔍 Verifying resource group access..." -ForegroundColor Gray
$rgCheck = az group show --name $resourceGroup --output json 2>$null
if ($LASTEXITCODE -eq 0) {
    Write-Host "  ✅ Resource group access confirmed" -ForegroundColor Green
} else {
    Write-Host "  ❌ Cannot access resource group '$resourceGroup'" -ForegroundColor Red
    Write-Host "     Please contact the admin to grant you access." -ForegroundColor Yellow
    exit 1
}

# Verify access to storage account
Write-Host "  🗄️ Verifying storage account access..." -ForegroundColor Gray
$storageCheck = az storage account show --name $storageAccount --resource-group $resourceGroup --output json 2>$null
if ($LASTEXITCODE -eq 0) {
    Write-Host "  ✅ Storage account access confirmed" -ForegroundColor Green
} else {
    Write-Host "  ❌ Cannot access storage account '$storageAccount'" -ForegroundColor Red
    Write-Host "     Please contact the admin to grant you storage access." -ForegroundColor Yellow
    exit 1
}

# Step 3: Verify we're in the right directory
Write-Host "`n📁 Step 3: Checking Directory Structure..." -ForegroundColor Cyan

if (-not (Test-Path "terraform-export-clean")) {
    Write-Host "  ❌ terraform-export-clean directory not found!" -ForegroundColor Red
    Write-Host "     Make sure you're in the root of the cloned repository." -ForegroundColor Yellow
    Write-Host "     Expected path: ./terraform-export-clean/" -ForegroundColor Yellow
    exit 1
}

Set-Location "terraform-export-clean"
Write-Host "  ✅ Changed to terraform-export-clean directory" -ForegroundColor Green

# Check for required files
$requiredFiles = @("backend.tf", "main.tf", "variables.tf", "resources.tf")
foreach ($file in $requiredFiles) {
    if (Test-Path $file) {
        Write-Host "  ✅ Found: $file" -ForegroundColor Green
    } else {
        Write-Host "  ❌ Missing: $file" -ForegroundColor Red
    }
}

# Step 4: Initialize Terraform
Write-Host "`n🏗️ Step 4: Initializing Terraform with Remote Backend..." -ForegroundColor Cyan

terraform init
if ($LASTEXITCODE -eq 0) {
    Write-Host "  ✅ Terraform initialized successfully!" -ForegroundColor Green
} else {
    Write-Host "  ❌ Terraform initialization failed!" -ForegroundColor Red
    Write-Host "     Check the error messages above for details." -ForegroundColor Yellow
    exit 1
}

# Step 5: Verify state access
Write-Host "`n📊 Step 5: Verifying Remote State Access..." -ForegroundColor Cyan

Write-Host "  📋 Listing resources in shared state..." -ForegroundColor Gray
$stateResources = terraform state list
if ($LASTEXITCODE -eq 0 -and $stateResources) {
    Write-Host "  ✅ Successfully connected to remote state!" -ForegroundColor Green
    Write-Host "  📦 Found $($stateResources.Count) managed resources:" -ForegroundColor Green
    foreach ($resource in $stateResources) {
        Write-Host "    • $resource" -ForegroundColor White
    }
} else {
    Write-Host "  ❌ Cannot access remote state or no resources found!" -ForegroundColor Red
    exit 1
}

# Step 6: Test plan
Write-Host "`n🔍 Step 6: Testing Terraform Plan..." -ForegroundColor Cyan

Write-Host "  🔄 Running terraform plan..." -ForegroundColor Gray
terraform plan -detailed-exitcode -no-color > plan-output.txt 2>&1
$planExitCode = $LASTEXITCODE

switch ($planExitCode) {
    0 { 
        Write-Host "  ✅ Plan successful - No changes needed" -ForegroundColor Green 
    }
    2 { 
        Write-Host "  ✅ Plan successful - Changes detected" -ForegroundColor Yellow
        Write-Host "     Review plan-output.txt for details" -ForegroundColor Gray
    }
    default { 
        Write-Host "  ❌ Plan failed!" -ForegroundColor Red
        Write-Host "     Check plan-output.txt for error details" -ForegroundColor Yellow
        Get-Content "plan-output.txt" | Select-Object -Last 10
    }
}

# Step 7: Success summary
Write-Host "`n🎉 Setup Complete!" -ForegroundColor Green
Write-Host "================================" -ForegroundColor Green

Write-Host "`n✅ Your environment is now configured for shared Terraform state!" -ForegroundColor Green

Write-Host "`n🔧 Next Steps:" -ForegroundColor Cyan
Write-Host "  1. Make your infrastructure changes in the .tf files"
Write-Host "  2. Run: terraform plan (to preview changes)"
Write-Host "  3. Run: terraform apply (to apply changes)"
Write-Host "  4. Coordinate with team members before major changes"

Write-Host "`n📚 Useful Commands:" -ForegroundColor Cyan
Write-Host "  terraform state list                    # List all managed resources"
Write-Host "  terraform state show <resource>         # Show resource details"
Write-Host "  terraform plan                          # Preview changes"
Write-Host "  terraform apply                         # Apply changes"
Write-Host "  terraform refresh                       # Sync state with Azure"

Write-Host "`n📋 Available Environment Configs:" -ForegroundColor Cyan
if (Test-Path "backend-dev.conf") { Write-Host "  • Development: terraform init -backend-config=backend-dev.conf" }
if (Test-Path "backend-test.conf") { Write-Host "  • Testing: terraform init -backend-config=backend-test.conf" }
if (Test-Path "backend-prod.conf") { Write-Host "  • Production: terraform init -backend-config=backend-prod.conf" }

Write-Host "`n🔗 Resources:" -ForegroundColor Cyan
Write-Host "  • Repository: https://github.com/rodrigotraid/my-eshoponweb"
Write-Host "  • Documentation: ./COLLEAGUE-ONBOARDING-GUIDE.md"
Write-Host "  • Azure Portal: https://portal.azure.com"

Write-Host "`n💡 Pro Tips:" -ForegroundColor Yellow
Write-Host "  • Always run 'terraform plan' before 'terraform apply'"
Write-Host "  • Communicate with team before making infrastructure changes"
Write-Host "  • Use the verification scripts for health checks"
Write-Host "  • Keep your changes small and focused"

Write-Host "`nHappy Terraforming! 🚀" -ForegroundColor Green

# Clean up
Remove-Item "plan-output.txt" -ErrorAction SilentlyContinue
