# Multi-Environment Deployment Script for eShopOnWeb
# Usage: .\deploy-environment.ps1 -Environment dev|test|prod|custom -TfvarsFile custom.tfvars

param(
    [Parameter(Mandatory=$true)]
    [ValidateSet("dev", "test", "prod", "original", "custom")]
    [string]$Environment,
    
    [Parameter(Mandatory=$false)]
    [string]$SubscriptionId,
    
    [Parameter(Mandatory=$false)]
    [string]$TenantId,
    
    [Parameter(Mandatory=$false)]
    [string]$TfvarsFile,
    
    [Parameter(Mandatory=$false)]
    [switch]$PlanOnly,
    
    [Parameter(Mandatory=$false)]
    [switch]$Destroy
)

Write-Host "🚀 eShopOnWeb Multi-Environment Deployment" -ForegroundColor Green
Write-Host "Environment: $Environment" -ForegroundColor Yellow

# Map environment to tfvars file
$tfvarsFile = switch ($Environment) {
    "dev" { "development.tfvars" }
    "test" { "test.tfvars" }
    "prod" { "production.tfvars" }
    "original" { $null }  # Use defaults (original configuration)
    "custom" { 
        if (-not $TfvarsFile) {
            Write-Error "❌ For custom environment, you must specify -TfvarsFile parameter!"
            exit 1
        }
        $TfvarsFile 
    }
}

# Check if tfvars file exists (except for original)
if ($Environment -ne "original" -and -not (Test-Path $tfvarsFile)) {
    Write-Error "❌ Configuration file $tfvarsFile not found!"
    exit 1
}

# Verify Azure CLI authentication
Write-Host "🔐 Checking Azure authentication..." -ForegroundColor Blue
try {
    $account = az account show | ConvertFrom-Json
    Write-Host "✅ Authenticated as: $($account.user.name)" -ForegroundColor Green
    Write-Host "   Subscription: $($account.name) ($($account.id))" -ForegroundColor Gray
} catch {
    Write-Error "❌ Not authenticated with Azure CLI. Run 'az login' first."
    exit 1
}

# Switch tenant if specified
if ($TenantId) {
    Write-Host "🏢 Switching to tenant: $TenantId" -ForegroundColor Blue
    az login --tenant $TenantId --only-show-errors
    if ($LASTEXITCODE -ne 0) {
        Write-Error "❌ Failed to switch to tenant $TenantId"
        exit 1
    }
    Write-Host "✅ Successfully switched to tenant: $TenantId" -ForegroundColor Green
}

# Switch subscription if specified
if ($SubscriptionId) {
    Write-Host "🔄 Switching to subscription: $SubscriptionId" -ForegroundColor Blue
    az account set --subscription $SubscriptionId
    if ($LASTEXITCODE -ne 0) {
        Write-Error "❌ Failed to switch to subscription $SubscriptionId"
        exit 1
    }
    Write-Host "✅ Successfully switched to subscription: $SubscriptionId" -ForegroundColor Green
}

# Initialize Terraform
Write-Host "🔧 Initializing Terraform..." -ForegroundColor Blue
terraform init
if ($LASTEXITCODE -ne 0) {
    Write-Error "❌ Terraform initialization failed"
    exit 1
}

# Prepare Terraform command
$terraformCmd = if ($Environment -eq "original") {
    "terraform"
} else {
    "terraform -var-file=`"$tfvarsFile`""
}

if ($Destroy) {
    # Destroy resources
    Write-Host "💥 DESTROYING resources for environment: $Environment" -ForegroundColor Red
    Write-Host "⚠️  This will delete all resources!" -ForegroundColor Yellow
    $confirmation = Read-Host "Type 'yes' to confirm destruction"
    
    if ($confirmation -eq "yes") {
        if ($Environment -eq "original") {
            terraform destroy -auto-approve
        } else {
            terraform destroy -var-file="$tfvarsFile" -auto-approve
        }
    } else {
        Write-Host "❌ Destruction cancelled" -ForegroundColor Yellow
        exit 0
    }
} else {
    # Plan or Apply
    Write-Host "📋 Creating Terraform plan..." -ForegroundColor Blue
    
    if ($Environment -eq "original") {
        terraform plan -out="$Environment.tfplan"
    } else {
        terraform plan -var-file="$tfvarsFile" -out="$Environment.tfplan"
    }
    
    if ($LASTEXITCODE -ne 0) {
        Write-Error "❌ Terraform plan failed"
        exit 1
    }
    
    if ($PlanOnly) {
        Write-Host "✅ Plan created successfully: $Environment.tfplan" -ForegroundColor Green
        Write-Host "📝 Review the plan above, then run without -PlanOnly to apply" -ForegroundColor Yellow
        exit 0
    }
    
    # Apply the plan
    Write-Host "🚀 Applying Terraform plan..." -ForegroundColor Blue
    Write-Host "⚠️  This will create Azure resources and may incur costs!" -ForegroundColor Yellow
    $confirmation = Read-Host "Press Enter to continue or Ctrl+C to cancel"
    
    terraform apply "$Environment.tfplan"
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Deployment completed successfully!" -ForegroundColor Green
        Write-Host ""
        Write-Host "📋 Outputs:" -ForegroundColor Blue
        terraform output
        
        Write-Host ""
        Write-Host "🎯 Next steps:" -ForegroundColor Yellow
        Write-Host "1. Get AKS credentials: az aks get-credentials --resource-group `$(terraform output -raw resource_group_name) --name `$(terraform output -raw aks_cluster_name)"
        Write-Host "2. Deploy your eShop application to the new cluster"
        Write-Host "3. Update your CI/CD pipelines to use the new ACR: `$(terraform output -raw container_registry_login_server)"
    } else {
        Write-Error "❌ Deployment failed"
        exit 1
    }
}

Write-Host ""
Write-Host "🏁 Script completed" -ForegroundColor Green
