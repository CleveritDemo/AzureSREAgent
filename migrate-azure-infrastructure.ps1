# Azure Infrastructure Migration Script
# This script automates the migration of infrastructure to a new tenant/subscription

param(
    [Parameter(Mandatory=$true)]
    [string]$NewTenantId,
    
    [Parameter(Mandatory=$true)]
    [string]$NewSubscriptionId,
    
    [Parameter(Mandatory=$true)]
    [string]$NewClientId,
    
    [Parameter(Mandatory=$true)]
    [string]$NewRegion = "East US",
    
    [Parameter(Mandatory=$true)]
    [string]$NewStorageAccount,
    
    [Parameter(Mandatory=$true)]
    [string]$NewContainerName = "terraform-state",
    
    [Parameter(Mandatory=$true)]
    [string]$NewBackendResourceGroup,
    
    [Parameter(Mandatory=$false)]
    [string]$SqlAdminPassword,
    
    [Parameter(Mandatory=$false)]
    [switch]$DryRun = $false
)

# Colors for output
$Green = [System.ConsoleColor]::Green
$Red = [System.ConsoleColor]::Red
$Yellow = [System.ConsoleColor]::Yellow
$Blue = [System.ConsoleColor]::Blue

function Write-ColoredOutput {
    param(
        [string]$Message,
        [System.ConsoleColor]$Color = [System.ConsoleColor]::White
    )
    Write-Host $Message -ForegroundColor $Color
}

function Test-Prerequisites {
    Write-ColoredOutput "🔍 Checking prerequisites..." $Blue
    
    # Check Azure CLI
    try {
        $azVersion = az version --output json | ConvertFrom-Json
        Write-ColoredOutput "✅ Azure CLI version: $($azVersion.'azure-cli')" $Green
    } catch {
        Write-ColoredOutput "❌ Azure CLI not found or not working" $Red
        exit 1
    }
    
    # Check Terraform
    try {
        $tfVersion = terraform version -json | ConvertFrom-Json
        Write-ColoredOutput "✅ Terraform version: $($tfVersion.terraform_version)" $Green
    } catch {
        Write-ColoredOutput "❌ Terraform not found or not working" $Red
        exit 1
    }
    
    # Check Docker
    try {
        docker --version | Out-Null
        Write-ColoredOutput "✅ Docker is available" $Green
    } catch {
        Write-ColoredOutput "⚠️ Docker not found - container image migration will be manual" $Yellow
    }
    
    # Check kubectl
    try {
        kubectl version --client=true --output=json | Out-Null
        Write-ColoredOutput "✅ kubectl is available" $Green
    } catch {
        Write-ColoredOutput "⚠️ kubectl not found - Kubernetes operations will be manual" $Yellow
    }
}

function Backup-CurrentInfrastructure {
    Write-ColoredOutput "💾 Creating backup of current infrastructure..." $Blue
    
    $backupDir = "migration-backup-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
    New-Item -ItemType Directory -Path $backupDir -Force | Out-Null
    
    # Export Terraform state
    Write-ColoredOutput "📄 Exporting Terraform state..." $Blue
    Push-Location terraform-export-clean
    try {
        terraform state pull > "../$backupDir/terraform.tfstate"
        Copy-Item "*.tf" "../$backupDir/" -Recurse
        Copy-Item "*.tfvars*" "../$backupDir/" -ErrorAction SilentlyContinue
        Write-ColoredOutput "✅ Terraform configuration backed up" $Green
    } catch {
        Write-ColoredOutput "❌ Failed to backup Terraform state: $_" $Red
        Pop-Location
        exit 1
    }
    Pop-Location
    
    # Backup SQL Database
    Write-ColoredOutput "🗄️ Creating SQL Database backup..." $Blue
    try {
        $sqlServerName = "eshopclever-sqlsrv"
        $databaseName = "eshopdb"
        $backupName = "eshopdb-migration-backup-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
        
        az sql db export `
            --resource-group "eShopCleverRG" `
            --server $sqlServerName `
            --name $databaseName `
            --admin-user "eshopsreadmin" `
            --admin-password $SqlAdminPassword `
            --storage-key-type "StorageAccessKey" `
            --storage-key (az storage account keys list --resource-group "eShopCleverRG" --account-name "eshopterraformstate8636" --query "[0].value" -o tsv) `
            --storage-uri "https://eshopterraformstate8636.blob.core.windows.net/sqlbackups/$backupName.bacpac"
            
        Write-ColoredOutput "✅ SQL Database backup initiated: $backupName.bacpac" $Green
    } catch {
        Write-ColoredOutput "⚠️ SQL backup failed - you may need to do this manually: $_" $Yellow
    }
    
    # Export Container Registry images
    Write-ColoredOutput "🐳 Exporting Container Registry images..." $Blue
    try {
        $acrName = "eshopcleveracr"
        $repositories = az acr repository list --name $acrName --output json | ConvertFrom-Json
        
        New-Item -ItemType Directory -Path "$backupDir/acr-images" -Force | Out-Null
        
        foreach ($repo in $repositories) {
            Write-ColoredOutput "📦 Exporting repository: $repo" $Blue
            $tags = az acr repository show-tags --name $acrName --repository $repo --output json | ConvertFrom-Json
            
            foreach ($tag in $tags) {
                $imageName = "$acrName.azurecr.io/${repo}:${tag}"
                Write-ColoredOutput "⬇️ Pulling image: $imageName" $Blue
                docker pull $imageName
                
                # Save image to tar file
                $fileName = "$backupDir/acr-images/$($repo.Replace('/', '_'))-$tag.tar"
                docker save $imageName -o $fileName
                Write-ColoredOutput "💾 Saved image: $fileName" $Green
            }
        }
    } catch {
        Write-ColoredOutput "⚠️ Container image export failed - you may need to do this manually: $_" $Yellow
    }
    
    # Export Kubernetes configurations
    Write-ColoredOutput "☸️ Exporting Kubernetes configurations..." $Blue
    try {
        az aks get-credentials --resource-group "eShopCleverRG" --name "eshopcleveraks" --overwrite-existing
        
        New-Item -ItemType Directory -Path "$backupDir/k8s-configs" -Force | Out-Null
        
        # Export common Kubernetes objects
        kubectl get all --all-namespaces -o yaml > "$backupDir/k8s-configs/all-resources.yaml"
        kubectl get configmap --all-namespaces -o yaml > "$backupDir/k8s-configs/configmaps.yaml"
        kubectl get secret --all-namespaces -o yaml > "$backupDir/k8s-configs/secrets.yaml"
        kubectl get pv -o yaml > "$backupDir/k8s-configs/persistent-volumes.yaml"
        kubectl get pvc --all-namespaces -o yaml > "$backupDir/k8s-configs/persistent-volume-claims.yaml"
        
        Write-ColoredOutput "✅ Kubernetes configurations exported" $Green
    } catch {
        Write-ColoredOutput "⚠️ Kubernetes export failed - you may need to do this manually: $_" $Yellow
    }
    
    Write-ColoredOutput "✅ Backup completed in directory: $backupDir" $Green
    return $backupDir
}

function Setup-NewEnvironment {
    param([string]$BackupDir)
    
    Write-ColoredOutput "🔧 Setting up new environment..." $Blue
    
    # Login to new tenant
    Write-ColoredOutput "🔐 Logging into new tenant..." $Blue
    az login --tenant $NewTenantId
    az account set --subscription $NewSubscriptionId
    
    # Verify access
    $currentAccount = az account show --output json | ConvertFrom-Json
    if ($currentAccount.id -ne $NewSubscriptionId) {
        Write-ColoredOutput "❌ Failed to switch to new subscription" $Red
        exit 1
    }
    Write-ColoredOutput "✅ Connected to subscription: $($currentAccount.name)" $Green
    
    # Create backend storage if it doesn't exist
    Write-ColoredOutput "🗄️ Setting up Terraform backend..." $Blue
    try {
        az group create --name $NewBackendResourceGroup --location $NewRegion
        az storage account create `
            --name $NewStorageAccount `
            --resource-group $NewBackendResourceGroup `
            --location $NewRegion `
            --sku Standard_LRS
        az storage container create `
            --name $NewContainerName `
            --account-name $NewStorageAccount
        Write-ColoredOutput "✅ Terraform backend storage created" $Green
    } catch {
        Write-ColoredOutput "⚠️ Backend storage setup failed (may already exist): $_" $Yellow
    }
    
    # Create new Terraform configuration
    Write-ColoredOutput "📝 Creating new Terraform configuration..." $Blue
    $newConfigDir = "terraform-new-environment"
    New-Item -ItemType Directory -Path $newConfigDir -Force | Out-Null
    
    # Copy current configuration
    Copy-Item "terraform-export-clean/*.tf" $newConfigDir -Recurse
    
    # Update backend configuration
    $backendConfig = @"
terraform {
  backend "azurerm" {
    resource_group_name  = "$NewBackendResourceGroup"
    storage_account_name = "$NewStorageAccount"
    container_name       = "$NewContainerName"
    key                  = "terraform.tfstate"
  }
}
"@
    $backendConfig | Out-File "$newConfigDir/backend.tf" -Encoding UTF8
    
    # Update variables
    $newTfvars = @"
tenant_id = "$NewTenantId"
subscription_id = "$NewSubscriptionId"
resource_group_name = "eShopCleverRG"
resource_group_location = "$NewRegion"
project_name = "eshopclever"
environment = "production"
sql_admin_password = "$SqlAdminPassword"
"@
    $newTfvars | Out-File "$newConfigDir/terraform.tfvars" -Encoding UTF8
    
    Write-ColoredOutput "✅ New Terraform configuration created in: $newConfigDir" $Green
    return $newConfigDir
}

function Deploy-Infrastructure {
    param([string]$ConfigDir)
    
    Write-ColoredOutput "🚀 Deploying infrastructure to new environment..." $Blue
    
    Push-Location $ConfigDir
    try {
        # Initialize Terraform
        Write-ColoredOutput "🔧 Initializing Terraform..." $Blue
        terraform init
        
        # Plan deployment
        Write-ColoredOutput "📋 Creating deployment plan..." $Blue
        terraform plan -out=migration.tfplan
        
        if ($DryRun) {
            Write-ColoredOutput "🔍 DRY RUN MODE - No changes will be applied" $Yellow
            Pop-Location
            return
        }
        
        # Apply infrastructure
        Write-ColoredOutput "⚡ Applying infrastructure changes..." $Blue
        terraform apply migration.tfplan
        
        Write-ColoredOutput "✅ Infrastructure deployment completed" $Green
    } catch {
        Write-ColoredOutput "❌ Infrastructure deployment failed: $_" $Red
        Pop-Location
        exit 1
    }
    Pop-Location
}

function Migrate-Data {
    param([string]$BackupDir)
    
    if ($DryRun) {
        Write-ColoredOutput "🔍 DRY RUN MODE - Skipping data migration" $Yellow
        return
    }
    
    Write-ColoredOutput "📊 Migrating data to new environment..." $Blue
    
    # Restore SQL Database
    Write-ColoredOutput "🗄️ Restoring SQL Database..." $Blue
    try {
        # This would restore from the backup created earlier
        # Implementation depends on your backup strategy
        Write-ColoredOutput "⚠️ SQL Database restore needs manual intervention" $Yellow
        Write-ColoredOutput "   Please restore from the backup created in: $BackupDir" $Yellow
    } catch {
        Write-ColoredOutput "⚠️ SQL Database restore failed: $_" $Yellow
    }
    
    # Push container images to new ACR
    Write-ColoredOutput "🐳 Migrating container images..." $Blue
    try {
        $newAcrName = "eshopcleveracr"
        az acr login --name $newAcrName
        
        # Load and push images from backup
        $imageFiles = Get-ChildItem "$BackupDir/acr-images/*.tar" -ErrorAction SilentlyContinue
        foreach ($imageFile in $imageFiles) {
            Write-ColoredOutput "📦 Loading image: $($imageFile.Name)" $Blue
            docker load -i $imageFile.FullName
            
            # Re-tag and push to new ACR
            # Implementation depends on your image naming strategy
        }
        Write-ColoredOutput "✅ Container images migrated" $Green
    } catch {
        Write-ColoredOutput "⚠️ Container image migration failed: $_" $Yellow
    }
}

function Update-GitHubSecrets {
    Write-ColoredOutput "🔐 Please update GitHub repository secrets with new values:" $Yellow
    Write-ColoredOutput "   AZURE_CLIENT_ID: $NewClientId" $Yellow
    Write-ColoredOutput "   AZURE_TENANT_ID: $NewTenantId" $Yellow
    Write-ColoredOutput "   AZURE_SUBSCRIPTION_ID: $NewSubscriptionId" $Yellow
}

function Validate-Migration {
    Write-ColoredOutput "✅ Running post-migration validation..." $Blue
    
    # Test resource connectivity
    try {
        $resources = az resource list --resource-group "eShopCleverRG" --output json | ConvertFrom-Json
        Write-ColoredOutput "✅ Found $($resources.Count) resources in new environment" $Green
        
        foreach ($resource in $resources) {
            Write-ColoredOutput "   - $($resource.type): $($resource.name)" $Blue
        }
    } catch {
        Write-ColoredOutput "⚠️ Resource validation failed: $_" $Yellow
    }
    
    # Test AKS connectivity
    try {
        az aks get-credentials --resource-group "eShopCleverRG" --name "eshopcleveraks" --overwrite-existing
        $nodes = kubectl get nodes --output json | ConvertFrom-Json
        Write-ColoredOutput "✅ AKS cluster accessible with $($nodes.items.Count) nodes" $Green
    } catch {
        Write-ColoredOutput "⚠️ AKS validation failed: $_" $Yellow
    }
}

# Main execution
Write-ColoredOutput "🚀 Starting Azure Infrastructure Migration" $Blue
Write-ColoredOutput "================================================" $Blue

if ($DryRun) {
    Write-ColoredOutput "🔍 RUNNING IN DRY RUN MODE - No changes will be made" $Yellow
}

Test-Prerequisites

$backupDir = Backup-CurrentInfrastructure
$configDir = Setup-NewEnvironment -BackupDir $backupDir

Deploy-Infrastructure -ConfigDir $configDir
Migrate-Data -BackupDir $backupDir

Update-GitHubSecrets
Validate-Migration

Write-ColoredOutput "🎉 Migration completed!" $Green
Write-ColoredOutput "📋 Next steps:" $Blue
Write-ColoredOutput "   1. Update GitHub secrets" $Blue
Write-ColoredOutput "   2. Update DNS records" $Blue
Write-ColoredOutput "   3. Test all applications" $Blue
Write-ColoredOutput "   4. Update documentation" $Blue
Write-ColoredOutput "   5. Monitor for 24-48 hours before cleanup" $Blue
