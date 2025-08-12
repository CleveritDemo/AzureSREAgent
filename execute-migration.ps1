# Azure Infrastructure Migration - Step by Step Execution
# This script provides a guided migration process

Write-Host "🚀 Azure Infrastructure Migration - Step by Step Guide" -ForegroundColor Blue
Write-Host "=====================================================" -ForegroundColor Blue
Write-Host ""

$steps = @(
    "🔍 Pre-migration validation",
    "💾 Backup current infrastructure", 
    "🔧 Setup new environment",
    "🚀 Deploy infrastructure",
    "📊 Migrate data", 
    "🔐 Update authentication",
    "✅ Validate migration",
    "🧹 Cleanup (optional)"
)

function Show-Step {
    param(
        [int]$StepNumber,
        [string]$Description,
        [string]$Status = "pending"
    )
    
    $icon = switch ($Status) {
        "pending" { "⏳" }
        "running" { "🔄" }
        "complete" { "✅" }
        "error" { "❌" }
        "skip" { "⏭️" }
        default { "⏳" }
    }
    
    Write-Host "$icon Step $StepNumber: $Description" -ForegroundColor $(
        switch ($Status) {
            "complete" { "Green" }
            "error" { "Red" }
            "running" { "Yellow" }
            "skip" { "Gray" }
            default { "White" }
        }
    )
}

function Confirm-Step {
    param([string]$Message)
    
    $response = Read-Host "$Message (y/n)"
    return $response -eq 'y' -or $response -eq 'Y' -or $response -eq 'yes'
}

function Execute-PreMigrationValidation {
    Show-Step 1 "Pre-migration validation" "running"
    
    Write-Host "🔍 Checking current environment..." -ForegroundColor Blue
    
    # Check current authentication
    try {
        $currentAccount = az account show --output json | ConvertFrom-Json
        Write-Host "✅ Current subscription: $($currentAccount.name)" -ForegroundColor Green
        Write-Host "✅ Current tenant: $($currentAccount.tenantId)" -ForegroundColor Green
    } catch {
        Show-Step 1 "Pre-migration validation" "error"
        Write-Host "❌ Failed to get current account info. Please run 'az login'" -ForegroundColor Red
        return $false
    }
    
    # Check Terraform state
    try {
        Push-Location terraform-export-clean
        $resources = terraform state list
        Write-Host "✅ Terraform state contains $($resources.Count) resources" -ForegroundColor Green
        Pop-Location
    } catch {
        Show-Step 1 "Pre-migration validation" "error"
        Write-Host "❌ Failed to read Terraform state" -ForegroundColor Red
        Pop-Location
        return $false
    }
    
    Show-Step 1 "Pre-migration validation" "complete"
    return $true
}

function Execute-Backup {
    Show-Step 2 "Backup current infrastructure" "running"
    
    $backupDir = "migration-backup-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
    New-Item -ItemType Directory -Path $backupDir -Force | Out-Null
    
    Write-Host "📁 Creating backup directory: $backupDir" -ForegroundColor Blue
    
    # Backup Terraform configuration
    Write-Host "📄 Backing up Terraform configuration..." -ForegroundColor Blue
    try {
        Push-Location terraform-export-clean
        terraform state pull > "../$backupDir/terraform.tfstate"
        Copy-Item "*.tf" "../$backupDir/" -Recurse -ErrorAction SilentlyContinue
        Copy-Item "*.tfvars*" "../$backupDir/" -Recurse -ErrorAction SilentlyContinue
        Pop-Location
        Write-Host "✅ Terraform configuration backed up" -ForegroundColor Green
    } catch {
        Write-Host "⚠️ Partial backup failure: $_" -ForegroundColor Yellow
    }
    
    # Export resource configurations
    Write-Host "📋 Exporting current resource configurations..." -ForegroundColor Blue
    try {
        az resource list --resource-group "eShopCleverRG" --output json > "$backupDir/current-resources.json"
        Write-Host "✅ Resource configurations exported" -ForegroundColor Green
    } catch {
        Write-Host "⚠️ Resource export failed: $_" -ForegroundColor Yellow
    }
    
    Show-Step 2 "Backup current infrastructure" "complete"
    Write-Host "💾 Backup completed in: $backupDir" -ForegroundColor Green
    return $backupDir
}

function Execute-NewEnvironmentSetup {
    Show-Step 3 "Setup new environment" "running"
    
    Write-Host "Please provide new environment details:" -ForegroundColor Yellow
    $newTenantId = Read-Host "New Tenant ID"
    $newSubscriptionId = Read-Host "New Subscription ID"
    $newClientId = Read-Host "New Service Principal Client ID"
    $newRegion = Read-Host "New Region (default: East US)"
    
    if ([string]::IsNullOrEmpty($newRegion)) {
        $newRegion = "East US"
    }
    
    # Generate configuration
    Write-Host "📝 Generating new environment configuration..." -ForegroundColor Blue
    & ./configure-new-environment.ps1 -NewTenantId $newTenantId -NewSubscriptionId $newSubscriptionId -NewClientId $newClientId -NewRegion $newRegion
    
    Show-Step 3 "Setup new environment" "complete"
    return @{
        TenantId = $newTenantId
        SubscriptionId = $newSubscriptionId
        ClientId = $newClientId
        Region = $newRegion
    }
}

function Execute-InfrastructureDeployment {
    param($NewEnvironment)
    
    Show-Step 4 "Deploy infrastructure" "running"
    
    Write-Host "🔐 Switching to new environment..." -ForegroundColor Blue
    az login --tenant $NewEnvironment.TenantId
    az account set --subscription $NewEnvironment.SubscriptionId
    
    Write-Host "🗄️ Setting up Terraform backend..." -ForegroundColor Blue
    # Create backend storage if needed
    $backendRG = "terraform-backend-rg"
    $storageAccount = "tfstate$(Get-Random -Minimum 1000 -Maximum 9999)"
    
    try {
        az group create --name $backendRG --location $NewEnvironment.Region
        az storage account create --name $storageAccount --resource-group $backendRG --location $NewEnvironment.Region --sku Standard_LRS
        az storage container create --name "terraform-state" --account-name $storageAccount
        Write-Host "✅ Terraform backend created" -ForegroundColor Green
    } catch {
        Write-Host "⚠️ Backend setup issue (may already exist): $_" -ForegroundColor Yellow
    }
    
    Write-Host "🚀 Deploying infrastructure..." -ForegroundColor Blue
    Write-Host "⚠️ This step requires manual Terraform execution:" -ForegroundColor Yellow
    Write-Host "1. Update terraform-export-clean/backend.tf with new backend settings" -ForegroundColor Yellow
    Write-Host "2. Update terraform-export-clean/terraform.tfvars with new values" -ForegroundColor Yellow
    Write-Host "3. Run: terraform init -reconfigure" -ForegroundColor Yellow
    Write-Host "4. Run: terraform plan" -ForegroundColor Yellow
    Write-Host "5. Run: terraform apply" -ForegroundColor Yellow
    
    if (Confirm-Step "Have you completed the Terraform deployment?") {
        Show-Step 4 "Deploy infrastructure" "complete"
        return $true
    } else {
        Show-Step 4 "Deploy infrastructure" "skip"
        return $false
    }
}

function Execute-DataMigration {
    Show-Step 5 "Migrate data" "running"
    
    Write-Host "📊 Data migration steps:" -ForegroundColor Blue
    Write-Host "1. SQL Database: Export from old, import to new" -ForegroundColor Yellow
    Write-Host "2. Container Registry: Pull images from old ACR, push to new ACR" -ForegroundColor Yellow
    Write-Host "3. Kubernetes: Redeploy applications with new configurations" -ForegroundColor Yellow
    
    Write-Host ""
    Write-Host "🗄️ SQL Database Migration:" -ForegroundColor Blue
    Write-Host "az sql db export --resource-group 'eShopCleverRG' --server 'eshopclever-sqlsrv' --name 'eshopdb' ..." -ForegroundColor Yellow
    Write-Host "az sql db import --resource-group 'eShopCleverRG' --server 'eshopclever-sqlsrv' --name 'eshopdb' ..." -ForegroundColor Yellow
    
    Write-Host ""
    Write-Host "🐳 Container Registry Migration:" -ForegroundColor Blue
    Write-Host "docker pull eshopcleveracr.azurecr.io/image:tag" -ForegroundColor Yellow
    Write-Host "docker tag eshopcleveracr.azurecr.io/image:tag newacr.azurecr.io/image:tag" -ForegroundColor Yellow
    Write-Host "docker push newacr.azurecr.io/image:tag" -ForegroundColor Yellow
    
    if (Confirm-Step "Have you completed the data migration?") {
        Show-Step 5 "Migrate data" "complete"
        return $true
    } else {
        Show-Step 5 "Migrate data" "skip"
        return $false
    }
}

function Execute-AuthenticationUpdate {
    param($NewEnvironment)
    
    Show-Step 6 "Update authentication" "running"
    
    Write-Host "🔐 GitHub Secrets to update:" -ForegroundColor Yellow
    Write-Host "AZURE_CLIENT_ID=$($NewEnvironment.ClientId)" -ForegroundColor Yellow
    Write-Host "AZURE_TENANT_ID=$($NewEnvironment.TenantId)" -ForegroundColor Yellow  
    Write-Host "AZURE_SUBSCRIPTION_ID=$($NewEnvironment.SubscriptionId)" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Update these in your GitHub repository settings:" -ForegroundColor Blue
    Write-Host "Repository → Settings → Secrets and variables → Actions" -ForegroundColor Blue
    
    if (Confirm-Step "Have you updated the GitHub secrets?") {
        Show-Step 6 "Update authentication" "complete"
        return $true
    } else {
        Show-Step 6 "Update authentication" "skip"
        return $false
    }
}

function Execute-ValidationAndCleanup {
    Show-Step 7 "Validate migration" "running"
    
    Write-Host "✅ Validation checklist:" -ForegroundColor Blue
    Write-Host "□ All resources created in new subscription" -ForegroundColor Yellow
    Write-Host "□ Applications accessible and functional" -ForegroundColor Yellow
    Write-Host "□ Database data migrated successfully" -ForegroundColor Yellow
    Write-Host "□ Container images available in new ACR" -ForegroundColor Yellow
    Write-Host "□ Kubernetes applications deployed and running" -ForegroundColor Yellow
    Write-Host "□ Chaos experiments configured and working" -ForegroundColor Yellow
    Write-Host "□ GitHub Actions workflows working with new authentication" -ForegroundColor Yellow
    
    if (Confirm-Step "Is the migration validation successful?") {
        Show-Step 7 "Validate migration" "complete"
        
        Write-Host ""
        if (Confirm-Step "Do you want to proceed with cleanup of old environment? (CAUTION: This is irreversible)") {
            Show-Step 8 "Cleanup" "running"
            Write-Host "⚠️ Cleanup commands (run manually after thorough validation):" -ForegroundColor Red
            Write-Host "az group delete --name 'eShopCleverRG' --yes --no-wait" -ForegroundColor Red
            Show-Step 8 "Cleanup" "skip"
        } else {
            Show-Step 8 "Cleanup" "skip"
            Write-Host "💡 Keep old environment for rollback until fully validated" -ForegroundColor Blue
        }
        return $true
    } else {
        Show-Step 7 "Validate migration" "error"
        Write-Host "❌ Migration validation failed. Please review and fix issues." -ForegroundColor Red
        return $false
    }
}

# Main execution
Write-Host "Migration Overview:" -ForegroundColor Blue
for ($i = 0; $i -lt $steps.Count; $i++) {
    Show-Step ($i + 1) $steps[$i] "pending"
}
Write-Host ""

if (-not (Confirm-Step "Ready to start migration?")) {
    Write-Host "Migration cancelled by user" -ForegroundColor Yellow
    exit
}

# Execute migration steps
$success = $true

# Step 1: Pre-migration validation
if ($success) { $success = Execute-PreMigrationValidation }

# Step 2: Backup
$backupDir = $null
if ($success) { $backupDir = Execute-Backup }

# Step 3: New environment setup
$newEnvironment = $null
if ($success) { $newEnvironment = Execute-NewEnvironmentSetup }

# Step 4: Infrastructure deployment
if ($success -and $newEnvironment) { $success = Execute-InfrastructureDeployment $newEnvironment }

# Step 5: Data migration
if ($success) { $success = Execute-DataMigration }

# Step 6: Authentication update
if ($success -and $newEnvironment) { $success = Execute-AuthenticationUpdate $newEnvironment }

# Step 7: Validation and cleanup
if ($success) { $success = Execute-ValidationAndCleanup }

# Final summary
Write-Host ""
Write-Host "🎉 Migration Process Summary:" -ForegroundColor Blue
Write-Host "=============================" -ForegroundColor Blue

if ($success) {
    Write-Host "✅ Migration completed successfully!" -ForegroundColor Green
    Write-Host "📋 Post-migration checklist:" -ForegroundColor Blue
    Write-Host "  1. Monitor applications for 24-48 hours" -ForegroundColor White
    Write-Host "  2. Update any external DNS records" -ForegroundColor White
    Write-Host "  3. Update documentation with new environment details" -ForegroundColor White
    Write-Host "  4. Test all GitHub Actions workflows" -ForegroundColor White
    Write-Host "  5. Test chaos experiments" -ForegroundColor White
    Write-Host "  6. Schedule cleanup of old environment after validation period" -ForegroundColor White
} else {
    Write-Host "❌ Migration encountered issues. Please review and retry." -ForegroundColor Red
    Write-Host "💾 Backup location: $backupDir" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "📞 Support: Check AZURE-INFRASTRUCTURE-MIGRATION-GUIDE.md for detailed guidance" -ForegroundColor Blue
