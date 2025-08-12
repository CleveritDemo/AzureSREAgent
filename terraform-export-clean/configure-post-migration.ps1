# Post-Migration Configuration Script
# This script helps configure services and secrets after successful migration

param(
    [Parameter(Mandatory=$true)]
    [string]$NewTenantId,
    
    [Parameter(Mandatory=$true)]
    [string]$NewSubscriptionId,
    
    [Parameter(Mandatory=$false)]
    [string]$NewResourceGroupName = "eShopCleverRG",
    
    [Parameter(Mandatory=$false)]
    [string]$ServicePrincipalName = "github-actions-eshop-chaos",
    
    [Parameter(Mandatory=$false)]
    [switch]$CreateServicePrincipal,
    
    [Parameter(Mandatory=$false)]
    [switch]$UpdateGitHubSecrets,
    
    [Parameter(Mandatory=$false)]
    [string]$GitHubRepo = "CleveritDemo/AzureSREAgent"
)

Write-Host "⚙️ Post-Migration Configuration Tool" -ForegroundColor Green
Write-Host "====================================" -ForegroundColor Green
Write-Host ""

# Function to create or update Service Principal
function New-ServicePrincipalForGitHub {
    Write-Host "🔐 Creating/Updating Service Principal for GitHub Actions..." -ForegroundColor Blue
    
    try {
        # Check if Service Principal already exists
        $existingSP = az ad sp list --display-name $ServicePrincipalName --query "[0]" | ConvertFrom-Json
        
        if ($existingSP) {
            Write-Host "   📝 Found existing Service Principal: $($existingSP.appId)" -ForegroundColor Cyan
            $clientId = $existingSP.appId
            $objectId = $existingSP.id
        } else {
            Write-Host "   ➕ Creating new Service Principal: $ServicePrincipalName" -ForegroundColor Cyan
            $sp = az ad sp create-for-rbac --name $ServicePrincipalName --role Contributor --scopes "/subscriptions/$NewSubscriptionId/resourceGroups/$NewResourceGroupName" | ConvertFrom-Json
            $clientId = $sp.appId
            $objectId = $sp.id
        }
        
        # Add additional role assignments for chaos experiments
        Write-Host "   🎯 Adding Chaos Studio Experiment Contributor role..." -ForegroundColor Cyan
        az role assignment create --assignee $clientId --role "Chaos Studio Experiment Contributor" --scope "/subscriptions/$NewSubscriptionId/resourceGroups/$NewResourceGroupName"
        
        # Add AKS Cluster User role for Kubernetes operations
        $aksCluster = az aks list --resource-group $NewResourceGroupName --query "[0].id" -o tsv
        if ($aksCluster) {
            Write-Host "   ☸️ Adding AKS Cluster User role..." -ForegroundColor Cyan
            az role assignment create --assignee $clientId --role "Azure Kubernetes Service Cluster User Role" --scope $aksCluster
        }
        
        Write-Host "✅ Service Principal configured successfully" -ForegroundColor Green
        Write-Host "   Client ID: $clientId" -ForegroundColor Gray
        Write-Host "   Object ID: $objectId" -ForegroundColor Gray
        Write-Host ""
        
        return @{
            ClientId = $clientId
            ObjectId = $objectId
        }
    }
    catch {
        Write-Host "❌ Failed to configure Service Principal: $($_.Exception.Message)" -ForegroundColor Red
        return $null
    }
}

# Function to configure OIDC federation for GitHub Actions
function Set-GitHubOIDCFederation {
    param($ServicePrincipal)
    
    Write-Host "🔗 Configuring OIDC federation for GitHub Actions..." -ForegroundColor Blue
    
    try {
        # Create federated identity credential for GitHub Actions
        Write-Host "   🎫 Creating federated identity credential..." -ForegroundColor Cyan
        
        $federatedIdentity = @{
            name = "github-actions-federation"
            issuer = "https://token.actions.githubusercontent.com"
            subject = "repo:$GitHubRepo:ref:refs/heads/main"
            description = "GitHub Actions OIDC for $GitHubRepo"
            audiences = @("api://AzureADTokenExchange")
        } | ConvertTo-Json -Depth 10
        
        $federatedIdentity | Out-File -FilePath "temp-federated-identity.json" -Encoding UTF8
        
        az ad app federated-credential create --id $ServicePrincipal.ClientId --parameters "temp-federated-identity.json"
        
        # Clean up temp file
        Remove-Item "temp-federated-identity.json" -Force
        
        Write-Host "✅ OIDC federation configured successfully" -ForegroundColor Green
        Write-Host ""
        
        return $true
    }
    catch {
        Write-Host "❌ Failed to configure OIDC federation: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

# Function to display GitHub Secrets configuration
function Show-GitHubSecretsConfiguration {
    param($ServicePrincipal)
    
    Write-Host "🔑 GitHub Secrets Configuration" -ForegroundColor Blue
    Write-Host "===============================" -ForegroundColor Blue
    Write-Host ""
    Write-Host "Please update the following secrets in your GitHub repository:" -ForegroundColor Yellow
    Write-Host "Repository: $GitHubRepo" -ForegroundColor Gray
    Write-Host "Path: Settings > Secrets and variables > Actions" -ForegroundColor Gray
    Write-Host ""
    
    Write-Host "Secret Name: AZURE_CLIENT_ID" -ForegroundColor Cyan
    Write-Host "Value: $($ServicePrincipal.ClientId)" -ForegroundColor White
    Write-Host ""
    
    Write-Host "Secret Name: AZURE_TENANT_ID" -ForegroundColor Cyan
    Write-Host "Value: $NewTenantId" -ForegroundColor White
    Write-Host ""
    
    Write-Host "Secret Name: AZURE_SUBSCRIPTION_ID" -ForegroundColor Cyan
    Write-Host "Value: $NewSubscriptionId" -ForegroundColor White
    Write-Host ""
    
    Write-Host "📋 Additional Configuration Updates Needed:" -ForegroundColor Blue
    Write-Host ""
    Write-Host "1. Update GitHub Actions workflows:" -ForegroundColor Yellow
    Write-Host "   - Update AZURE_SUBSCRIPTION_ID in workflow environment variables" -ForegroundColor Gray
    Write-Host "   - Verify OIDC permissions are configured" -ForegroundColor Gray
    Write-Host ""
    Write-Host "2. Update backend configuration files:" -ForegroundColor Yellow
    Write-Host "   - Update storage account name in backend-*.conf files" -ForegroundColor Gray
    Write-Host "   - Update resource group name if changed" -ForegroundColor Gray
    Write-Host ""
    Write-Host "3. Test chaos experiments:" -ForegroundColor Yellow
    Write-Host "   - Run validation scripts to ensure everything works" -ForegroundColor Gray
    Write-Host "   - Test GitHub Actions workflows" -ForegroundColor Gray
}

# Function to update workflow files
function Update-WorkflowFiles {
    Write-Host "📝 Updating GitHub Actions workflow files..." -ForegroundColor Blue
    
    $workflowFiles = @(
        "..\.github\workflows\provision-chaos-experiment.yml",
        "..\.github\workflows\chaos-experiments.yml",
        "..\.github\workflows\deploy-infrastructure.yml"
    )
    
    foreach ($file in $workflowFiles) {
        if (Test-Path $file) {
            Write-Host "   📄 Updating $file..." -ForegroundColor Cyan
            
            # Read current content
            $content = Get-Content $file -Raw
            
            # Update subscription ID if it's hardcoded
            $content = $content -replace "5f62fee3-b00a-44d2-86e5-5cf130b28b5d", $NewSubscriptionId
            
            # Save updated content
            $content | Out-File -FilePath $file -Encoding UTF8
            
            Write-Host "   ✅ Updated $file" -ForegroundColor Green
        } else {
            Write-Host "   ⚠️ File not found: $file" -ForegroundColor Yellow
        }
    }
    
    Write-Host "✅ Workflow files updated" -ForegroundColor Green
    Write-Host ""
}

# Function to verify migration success
function Test-MigrationSuccess {
    Write-Host "🔍 Verifying migration success..." -ForegroundColor Blue
    
    try {
        # Check if all expected resources exist
        Write-Host "   📋 Checking resource existence..." -ForegroundColor Cyan
        $resources = az resource list --resource-group $NewResourceGroupName | ConvertFrom-Json
        
        $expectedResources = @(
            "Microsoft.ContainerRegistry/registries",
            "Microsoft.Sql/servers",
            "Microsoft.Sql/servers/databases",
            "Microsoft.ContainerService/managedClusters"
        )
        
        $foundResources = @()
        foreach ($expectedType in $expectedResources) {
            $found = $resources | Where-Object { $_.type -eq $expectedType }
            if ($found) {
                $foundResources += $expectedType
                Write-Host "   ✅ Found: $expectedType" -ForegroundColor Green
            } else {
                Write-Host "   ❌ Missing: $expectedType" -ForegroundColor Red
            }
        }
        
        # Check AKS cluster status
        Write-Host "   ☸️ Checking AKS cluster status..." -ForegroundColor Cyan
        $aksStatus = az aks show --resource-group $NewResourceGroupName --name "eshopcleveraks" --query "provisioningState" -o tsv
        if ($aksStatus -eq "Succeeded") {
            Write-Host "   ✅ AKS cluster is ready" -ForegroundColor Green
        } else {
            Write-Host "   ⚠️ AKS cluster status: $aksStatus" -ForegroundColor Yellow
        }
        
        # Check SQL server connectivity
        Write-Host "   🗄️ Checking SQL server status..." -ForegroundColor Cyan
        $sqlServer = az sql server show --resource-group $NewResourceGroupName --name "eshopclever-sqlsrv" --query "state" -o tsv
        if ($sqlServer -eq "Ready") {
            Write-Host "   ✅ SQL server is ready" -ForegroundColor Green
        } else {
            Write-Host "   ⚠️ SQL server status: $sqlServer" -ForegroundColor Yellow
        }
        
        Write-Host "✅ Migration verification completed" -ForegroundColor Green
        Write-Host "   Resources found: $($foundResources.Count)/$($expectedResources.Count)" -ForegroundColor Gray
        Write-Host ""
        
        return $true
    }
    catch {
        Write-Host "❌ Migration verification failed: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

# Main execution
Write-Host "🎯 Post-Migration Configuration:" -ForegroundColor Yellow
Write-Host "   New Tenant: $NewTenantId" -ForegroundColor Gray
Write-Host "   New Subscription: $NewSubscriptionId" -ForegroundColor Gray
Write-Host "   Resource Group: $NewResourceGroupName" -ForegroundColor Gray
Write-Host "   GitHub Repository: $GitHubRepo" -ForegroundColor Gray
Write-Host ""

try {
    # Ensure we're authenticated to the new tenant/subscription
    Write-Host "🔐 Ensuring authentication to new environment..." -ForegroundColor Blue
    az account set --subscription $NewSubscriptionId
    
    $servicePrincipal = $null
    if ($CreateServicePrincipal) {
        $servicePrincipal = New-ServicePrincipalForGitHub
        if ($servicePrincipal) {
            Set-GitHubOIDCFederation -ServicePrincipal $servicePrincipal
        }
    } else {
        # Try to find existing service principal
        $existingSP = az ad sp list --display-name $ServicePrincipalName --query "[0]" | ConvertFrom-Json
        if ($existingSP) {
            $servicePrincipal = @{
                ClientId = $existingSP.appId
                ObjectId = $existingSP.id
            }
        }
    }
    
    # Update workflow files
    Update-WorkflowFiles
    
    # Verify migration
    Test-MigrationSuccess
    
    # Show configuration information
    if ($servicePrincipal) {
        Show-GitHubSecretsConfiguration -ServicePrincipal $servicePrincipal
    }
    
    Write-Host "🎉 Post-migration configuration completed!" -ForegroundColor Green
    Write-Host ""
    Write-Host "📋 Next Steps:" -ForegroundColor Blue
    Write-Host "   1. Update GitHub repository secrets with the values shown above" -ForegroundColor Gray
    Write-Host "   2. Test GitHub Actions workflows" -ForegroundColor Gray
    Write-Host "   3. Verify applications are accessible" -ForegroundColor Gray
    Write-Host "   4. Update any external documentation with new resource details" -ForegroundColor Gray
    
} catch {
    Write-Host "❌ Post-migration configuration failed: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}
