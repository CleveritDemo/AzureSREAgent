# Cross-Tenant/Cross-Subscription Infrastructure Migration Script
# This script migrates all eShopOnWeb infrastructure to a new tenant/subscription while preserving resource names and configurations

param(
    [Parameter(Mandatory=$true)]
    [string]$TargetTenantId,
    
    [Parameter(Mandatory=$true)]
    [string]$TargetSubscriptionId,
    
    [Parameter(Mandatory=$false)]
    [string]$TargetResourceGroupName = "eShopCleverRG",  # Keep same name by default
    
    [Parameter(Mandatory=$false)]
    [string]$TargetLocation = "East US 2",
    
    [Parameter(Mandatory=$false)]
    [SecureString]$SqlAdminPassword,
    
    [Parameter(Mandatory=$false)]
    [switch]$PlanOnly,
    
    [Parameter(Mandatory=$false)]
    [switch]$SkipSourceExport,
    
    [Parameter(Mandatory=$false)]
    [switch]$DestroySource,
    
    [Parameter(Mandatory=$false)]
    [switch]$CreateStateBackend,
    
    [Parameter(Mandatory=$false)]
    [string]$BackupPath = ".\migration-backup"
)

Write-Host "🚀 Cross-Tenant Infrastructure Migration Tool" -ForegroundColor Green
Write-Host "=========================================" -ForegroundColor Green
Write-Host ""

# Ensure backup directory exists
if (-not (Test-Path $BackupPath)) {
    New-Item -ItemType Directory -Path $BackupPath -Force | Out-Null
}

$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"

# Function to export current state
function Export-CurrentState {
    Write-Host "📋 Step 1: Exporting current infrastructure state..." -ForegroundColor Blue
    
    # Export current Terraform state
    Write-Host "   📄 Backing up current Terraform state..." -ForegroundColor Cyan
    terraform state pull > "$BackupPath\source-terraform-$timestamp.tfstate"
    
    # Export current resource list
    Write-Host "   📝 Exporting resource inventory..." -ForegroundColor Cyan
    terraform state list > "$BackupPath\source-resources-$timestamp.txt"
    
    # Export current configuration
    Write-Host "   ⚙️ Backing up current configuration..." -ForegroundColor Cyan
    Copy-Item "variables.tf" "$BackupPath\source-variables-$timestamp.tf"
    Copy-Item "main.tf" "$BackupPath\source-main-$timestamp.tf"
    Copy-Item "resources.tf" "$BackupPath\source-resources-$timestamp.tf"
    
    # Get current Azure resources via CLI
    Write-Host "   🔍 Exporting Azure resource details..." -ForegroundColor Cyan
    az resource list --resource-group $TargetResourceGroupName --output json > "$BackupPath\azure-resources-$timestamp.json"
    
    Write-Host "✅ Current state exported to: $BackupPath" -ForegroundColor Green
    Write-Host ""
}

# Function to authenticate to target tenant
function Connect-TargetTenant {
    Write-Host "🔐 Step 2: Authenticating to target tenant..." -ForegroundColor Blue
    
    try {
        Write-Host "   🏢 Switching to tenant: $TargetTenantId" -ForegroundColor Cyan
        az login --tenant $TargetTenantId --allow-no-subscriptions
        
        Write-Host "   📊 Setting target subscription: $TargetSubscriptionId" -ForegroundColor Cyan
        az account set --subscription $TargetSubscriptionId
        
        # Verify access
        $currentAccount = az account show | ConvertFrom-Json
        Write-Host "✅ Successfully authenticated to:" -ForegroundColor Green
        Write-Host "   Tenant: $($currentAccount.tenantId)" -ForegroundColor Gray
        Write-Host "   Subscription: $($currentAccount.name) ($($currentAccount.id))" -ForegroundColor Gray
        Write-Host ""
        
        return $true
    }
    catch {
        Write-Host "❌ Failed to authenticate to target tenant: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

# Function to create target state backend
function New-TargetStateBackend {
    if (-not $CreateStateBackend) {
        Write-Host "⏭️ Skipping state backend creation (use -CreateStateBackend to create)" -ForegroundColor Yellow
        return $true
    }
    
    Write-Host "🗄️ Step 3: Creating target Terraform state backend..." -ForegroundColor Blue
    
    try {
        # Create resource group for state backend
        Write-Host "   📁 Creating resource group: $TargetResourceGroupName" -ForegroundColor Cyan
        az group create --name $TargetResourceGroupName --location $TargetLocation
        
        # Create storage account for Terraform state
        $storageAccountName = "eshopterraformstate$(Get-Random -Minimum 1000 -Maximum 9999)"
        Write-Host "   💾 Creating storage account: $storageAccountName" -ForegroundColor Cyan
        az storage account create `
            --resource-group $TargetResourceGroupName `
            --name $storageAccountName `
            --sku Standard_LRS `
            --encryption-services blob
        
        # Create container
        Write-Host "   📦 Creating container: tfstate" -ForegroundColor Cyan
        az storage container create `
            --name tfstate `
            --account-name $storageAccountName
            
        # Create new backend configuration
        Write-Host "   ⚙️ Creating target backend configuration..." -ForegroundColor Cyan
        @"
resource_group_name  = "$TargetResourceGroupName"
storage_account_name = "$storageAccountName"
container_name       = "tfstate"
key                  = "terraform.tfstate"
"@ | Out-File -FilePath "backend-target.conf" -Encoding UTF8
        
        Write-Host "✅ Target state backend created" -ForegroundColor Green
        Write-Host "   Storage Account: $storageAccountName" -ForegroundColor Gray
        Write-Host "   Configuration saved to: backend-target.conf" -ForegroundColor Gray
        Write-Host ""
        
        return $storageAccountName
    }
    catch {
        Write-Host "❌ Failed to create state backend: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

# Function to create target configuration
function New-TargetConfiguration {
    Write-Host "⚙️ Step 4: Creating target environment configuration..." -ForegroundColor Blue
    
    # Create target tfvars file
    $targetTfvars = @"
# Target Environment Configuration - Generated $timestamp
subscription_id           = "$TargetSubscriptionId"
tenant_id                = "$TargetTenantId"
resource_group_name       = "$TargetResourceGroupName"
resource_group_location   = "$TargetLocation"

# Keep same resource naming to maintain consistency
project_name             = "eshopclever"
environment              = "migrated"

# Security Configuration
sql_admin_password       = "$([Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($SqlAdminPassword)))"
ssh_public_key          = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC33ECCPzwTwcnPvlI/ivFIgINIleg8Yxxe8aNHek5fpgr0dVfkNgmIYqP4F7Je9hBsdlIP1EFC/OU7Mepele4dSlEY4DJmSDQUH4BhAN+fGhKmt1k847dZezP0KGSli8LqdvWL3k2s3WsSPkEg4AD1A5jqDsKBUPN60giMJxT0tDvMuo59kVleJWR05NfzshKWvDuBLBaGmsRLcNBY+EnJcNHVU/ufMDifYq9HUOPd5PxTsprlU0uy5MDp0GvYEqhu/cIW48tF8AfIXfDjiI4vlXje2KtJhlZfehQ0FaMUkJPk/1yZqXbNxm5YRwwCOIeUkBLLkZUu+3Yt7KK2YBjR"
"@
    
    $targetTfvars | Out-File -FilePath "target-migration.tfvars" -Encoding UTF8
    
    # Copy current Terraform files for backup
    Copy-Item "variables.tf" "$BackupPath\target-variables-$timestamp.tf"
    
    Write-Host "✅ Target configuration created: target-migration.tfvars" -ForegroundColor Green
    Write-Host ""
}

# Function to plan migration
function Invoke-MigrationPlan {
    Write-Host "📋 Step 5: Planning infrastructure migration..." -ForegroundColor Blue
    
    try {
        # Initialize with target backend if specified
        if ($CreateStateBackend -and (Test-Path "backend-target.conf")) {
            Write-Host "   🔄 Initializing with target backend..." -ForegroundColor Cyan
            terraform init -backend-config="backend-target.conf" -reconfigure
        } else {
            Write-Host "   🔄 Initializing with default backend..." -ForegroundColor Cyan
            terraform init
        }
        
        # Run terraform plan
        Write-Host "   📊 Generating deployment plan..." -ForegroundColor Cyan
        terraform plan -var-file="target-migration.tfvars" -out="migration-plan-$timestamp.tfplan"
        
        # Save plan output for review
        terraform show -no-color "migration-plan-$timestamp.tfplan" > "$BackupPath\migration-plan-$timestamp.txt"
        
        Write-Host "✅ Migration plan generated" -ForegroundColor Green
        Write-Host "   Plan file: migration-plan-$timestamp.tfplan" -ForegroundColor Gray
        Write-Host "   Plan details: $BackupPath\migration-plan-$timestamp.txt" -ForegroundColor Gray
        Write-Host ""
        
        return $true
    }
    catch {
        Write-Host "❌ Failed to generate migration plan: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

# Function to apply migration
function Invoke-MigrationApply {
    Write-Host "🚀 Step 6: Applying infrastructure migration..." -ForegroundColor Blue
    
    try {
        Write-Host "   ⚠️ This will create all resources in the target tenant/subscription" -ForegroundColor Yellow
        
        if (-not $PlanOnly) {
            $confirmation = Read-Host "   Do you want to proceed with the migration? (yes/no)"
            if ($confirmation -ne "yes") {
                Write-Host "❌ Migration cancelled by user" -ForegroundColor Red
                return $false
            }
        }
        
        if (-not $PlanOnly) {
            Write-Host "   🔧 Applying migration plan..." -ForegroundColor Cyan
            terraform apply "migration-plan-$timestamp.tfplan"
            
            Write-Host "✅ Infrastructure migration completed!" -ForegroundColor Green
            Write-Host ""
            
            # Show outputs
            Write-Host "📊 Migration Results:" -ForegroundColor Blue
            terraform output
        } else {
            Write-Host "⏭️ Plan-only mode: Migration not applied" -ForegroundColor Yellow
        }
        
        return $true
    }
    catch {
        Write-Host "❌ Failed to apply migration: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

# Function to verify migration
function Test-Migration {
    Write-Host "✅ Step 7: Verifying migration..." -ForegroundColor Blue
    
    try {
        # List created resources
        Write-Host "   📋 Listing created resources..." -ForegroundColor Cyan
        terraform state list
        
        # Verify specific resources exist in Azure
        Write-Host "   🔍 Verifying resources in Azure..." -ForegroundColor Cyan
        $resources = az resource list --resource-group $TargetResourceGroupName --output json | ConvertFrom-Json
        
        Write-Host "   📊 Migration Summary:" -ForegroundColor Cyan
        Write-Host "      Resource Group: $TargetResourceGroupName" -ForegroundColor Gray
        Write-Host "      Resources Created: $($resources.Count)" -ForegroundColor Gray
        Write-Host "      Tenant: $TargetTenantId" -ForegroundColor Gray
        Write-Host "      Subscription: $TargetSubscriptionId" -ForegroundColor Gray
        
        # Save verification results
        $resources | ConvertTo-Json -Depth 10 > "$BackupPath\target-resources-$timestamp.json"
        
        Write-Host "✅ Migration verification completed" -ForegroundColor Green
        Write-Host ""
        
        return $true
    }
    catch {
        Write-Host "❌ Migration verification failed: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

# Function to destroy source infrastructure (optional)
function Remove-SourceInfrastructure {
    if (-not $DestroySource) {
        Write-Host "⏭️ Skipping source infrastructure destruction (use -DestroySource to destroy)" -ForegroundColor Yellow
        return $true
    }
    
    Write-Host "🗑️ Step 8: Destroying source infrastructure..." -ForegroundColor Blue
    Write-Host "   ⚠️ WARNING: This will permanently delete all source infrastructure!" -ForegroundColor Red
    
    $confirmation = Read-Host "   Type 'DESTROY' to confirm destruction of source infrastructure"
    if ($confirmation -ne "DESTROY") {
        Write-Host "❌ Source destruction cancelled" -ForegroundColor Red
        return $false
    }
    
    try {
        # Switch back to source tenant/subscription
        # This would need to be implemented based on your source credentials
        Write-Host "   🔄 This step requires manual implementation for your source environment" -ForegroundColor Yellow
        Write-Host "   📋 Use the source state backup to destroy resources if needed" -ForegroundColor Yellow
        
        return $true
    }
    catch {
        Write-Host "❌ Failed to destroy source infrastructure: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

# Main execution flow
Write-Host "🎯 Migration Configuration:" -ForegroundColor Yellow
Write-Host "   Target Tenant: $TargetTenantId" -ForegroundColor Gray
Write-Host "   Target Subscription: $TargetSubscriptionId" -ForegroundColor Gray
Write-Host "   Target Resource Group: $TargetResourceGroupName" -ForegroundColor Gray
Write-Host "   Target Location: $TargetLocation" -ForegroundColor Gray
Write-Host "   Plan Only: $PlanOnly" -ForegroundColor Gray
Write-Host "   Create State Backend: $CreateStateBackend" -ForegroundColor Gray
Write-Host ""

# Validate required parameters
if (-not $SqlAdminPassword) {
    $SqlAdminPassword = Read-Host "Enter SQL Server administrator password" -AsSecureString
}

try {
    # Execute migration steps
    if (-not $SkipSourceExport) {
        Export-CurrentState
    }
    
    if (-not (Connect-TargetTenant)) {
        throw "Failed to connect to target tenant"
    }
    
    $storageAccount = New-TargetStateBackend
    if ($CreateStateBackend -and -not $storageAccount) {
        throw "Failed to create target state backend"
    }
    
    New-TargetConfiguration
    
    if (-not (Invoke-MigrationPlan)) {
        throw "Failed to generate migration plan"
    }
    
    if (-not (Invoke-MigrationApply)) {
        throw "Failed to apply migration"
    }
    
    if (-not (Test-Migration)) {
        throw "Migration verification failed"
    }
    
    Remove-SourceInfrastructure
    
    Write-Host "🎉 Migration completed successfully!" -ForegroundColor Green
    Write-Host "📁 All migration artifacts saved to: $BackupPath" -ForegroundColor Green
    Write-Host ""
    
    Write-Host "📋 Next Steps:" -ForegroundColor Blue
    Write-Host "   1. Verify all applications work in the new environment" -ForegroundColor Gray
    Write-Host "   2. Update any external references to point to new resources" -ForegroundColor Gray
    Write-Host "   3. Update GitHub Actions secrets with new tenant/subscription IDs" -ForegroundColor Gray
    Write-Host "   4. Test chaos experiments in the new environment" -ForegroundColor Gray
    Write-Host "   5. Consider destroying source infrastructure when confident" -ForegroundColor Gray
    
} catch {
    Write-Host "❌ Migration failed: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "📁 Check migration artifacts in: $BackupPath" -ForegroundColor Yellow
    exit 1
}
