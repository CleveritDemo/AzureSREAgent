# Export Current Infrastructure Configuration
# This script exports your current infrastructure details for migration

Write-Host "📊 Exporting Current Infrastructure Configuration" -ForegroundColor Blue
Write-Host "===============================================" -ForegroundColor Blue

$exportDir = "infrastructure-export-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
New-Item -ItemType Directory -Path $exportDir -Force | Out-Null

Write-Host "📁 Export directory: $exportDir" -ForegroundColor Green

# Export current account info
Write-Host "🔐 Exporting current authentication info..." -ForegroundColor Blue
$currentAccount = az account show --output json | ConvertFrom-Json
$accountInfo = @{
    CurrentTenant = $currentAccount.tenantId
    CurrentSubscription = $currentAccount.id
    CurrentSubscriptionName = $currentAccount.name
    ExportDate = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
}
$accountInfo | ConvertTo-Json | Out-File "$exportDir/current-environment.json" -Encoding UTF8

# Export resource group details
Write-Host "🏗️ Exporting resource group details..." -ForegroundColor Blue
$resourceGroup = az group show --name "eShopCleverRG" --output json | ConvertFrom-Json
$resourceGroup | ConvertTo-Json -Depth 10 | Out-File "$exportDir/resource-group.json" -Encoding UTF8

# Export all resources in the resource group
Write-Host "📋 Exporting all resources..." -ForegroundColor Blue
$resources = az resource list --resource-group "eShopCleverRG" --output json | ConvertFrom-Json
$resources | ConvertTo-Json -Depth 10 | Out-File "$exportDir/all-resources.json" -Encoding UTF8

# Export specific resource configurations
Write-Host "🔧 Exporting detailed resource configurations..." -ForegroundColor Blue

# AKS Cluster
try {
    $aks = az aks show --resource-group "eShopCleverRG" --name "eshopcleveraks" --output json | ConvertFrom-Json
    $aks | ConvertTo-Json -Depth 10 | Out-File "$exportDir/aks-cluster.json" -Encoding UTF8
    Write-Host "✅ AKS cluster configuration exported" -ForegroundColor Green
} catch {
    Write-Host "⚠️ Could not export AKS configuration: $_" -ForegroundColor Yellow
}

# Container Registry
try {
    $acr = az acr show --name "eshopcleveracr" --output json | ConvertFrom-Json
    $acr | ConvertTo-Json -Depth 10 | Out-File "$exportDir/container-registry.json" -Encoding UTF8
    
    # Export repository list
    $repos = az acr repository list --name "eshopcleveracr" --output json | ConvertFrom-Json
    $repos | ConvertTo-Json | Out-File "$exportDir/acr-repositories.json" -Encoding UTF8
    Write-Host "✅ Container Registry configuration exported" -ForegroundColor Green
} catch {
    Write-Host "⚠️ Could not export ACR configuration: $_" -ForegroundColor Yellow
}

# SQL Server and Database
try {
    $sqlServer = az sql server show --resource-group "eShopCleverRG" --name "eshopclever-sqlsrv" --output json | ConvertFrom-Json
    $sqlServer | ConvertTo-Json -Depth 10 | Out-File "$exportDir/sql-server.json" -Encoding UTF8
    
    $sqlDb = az sql db show --resource-group "eShopCleverRG" --server "eshopclever-sqlsrv" --name "eshopdb" --output json | ConvertFrom-Json
    $sqlDb | ConvertTo-Json -Depth 10 | Out-File "$exportDir/sql-database.json" -Encoding UTF8
    Write-Host "✅ SQL Server and Database configuration exported" -ForegroundColor Green
} catch {
    Write-Host "⚠️ Could not export SQL configuration: $_" -ForegroundColor Yellow
}

# Export Terraform state
Write-Host "📄 Exporting Terraform state..." -ForegroundColor Blue
try {
    Push-Location terraform-export-clean
    terraform state pull > "../$exportDir/terraform.tfstate"
    terraform state list > "../$exportDir/terraform-resources.txt"
    
    # Copy Terraform configuration files
    Copy-Item "*.tf" "../$exportDir/" -ErrorAction SilentlyContinue
    Copy-Item "*.tfvars*" "../$exportDir/" -ErrorAction SilentlyContinue
    Pop-Location
    Write-Host "✅ Terraform configuration exported" -ForegroundColor Green
} catch {
    Write-Host "⚠️ Could not export Terraform state: $_" -ForegroundColor Yellow
    Pop-Location
}

# Export Kubernetes configurations
Write-Host "☸️ Exporting Kubernetes configurations..." -ForegroundColor Blue
try {
    az aks get-credentials --resource-group "eShopCleverRG" --name "eshopcleveraks" --overwrite-existing
    
    # Export all resources in eshop namespace
    kubectl get all -n eshop -o yaml > "$exportDir/k8s-eshop-namespace.yaml" 2>$null
    
    # Export common resources
    kubectl get configmap --all-namespaces -o yaml > "$exportDir/k8s-configmaps.yaml" 2>$null
    kubectl get secret --all-namespaces -o yaml > "$exportDir/k8s-secrets.yaml" 2>$null
    kubectl get ingress --all-namespaces -o yaml > "$exportDir/k8s-ingress.yaml" 2>$null
    kubectl get pv -o yaml > "$exportDir/k8s-persistent-volumes.yaml" 2>$null
    kubectl get pvc --all-namespaces -o yaml > "$exportDir/k8s-persistent-volume-claims.yaml" 2>$null
    
    Write-Host "✅ Kubernetes configurations exported" -ForegroundColor Green
} catch {
    Write-Host "⚠️ Could not export Kubernetes configurations: $_" -ForegroundColor Yellow
}

# Create migration summary
$summary = @"
# Infrastructure Migration Summary
Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')

## Current Environment
- Tenant ID: $($currentAccount.tenantId)
- Subscription ID: $($currentAccount.id)
- Subscription Name: $($currentAccount.name)
- Resource Group: eShopCleverRG
- Location: $($resourceGroup.location)

## Resources Found
- Total Resources: $($resources.Count)
- AKS Cluster: eshopcleveraks
- Container Registry: eshopcleveracr
- SQL Server: eshopclever-sqlsrv
- SQL Database: eshopdb

## Migration Requirements
1. New tenant and subscription with same resource quotas
2. Service Principal with Contributor and Chaos Studio permissions
3. Same resource names available in new environment
4. Network connectivity for data transfer

## Files Exported
- current-environment.json - Current authentication details
- resource-group.json - Resource group configuration
- all-resources.json - All resources in the resource group
- aks-cluster.json - AKS cluster detailed configuration
- container-registry.json - ACR configuration
- acr-repositories.json - List of container repositories
- sql-server.json - SQL Server configuration
- sql-database.json - SQL Database configuration
- terraform.tfstate - Current Terraform state
- terraform-resources.txt - List of Terraform-managed resources
- *.tf - Terraform configuration files
- k8s-*.yaml - Kubernetes resource configurations

## Next Steps
1. Review exported configurations
2. Prepare new environment (tenant/subscription)
3. Create Service Principal with required permissions
4. Update Terraform configuration for new environment
5. Execute migration using migration scripts
6. Validate migrated infrastructure
7. Update DNS and external configurations
8. Test all applications and workflows

## Important Notes
- Keep this export as backup during migration
- Verify all resource names are available in new environment
- Some globally unique names (ACR, SQL Server) may need temporary alternatives
- Plan for minimal downtime during DNS switchover
"@

$summary | Out-File "$exportDir/MIGRATION-SUMMARY.md" -Encoding UTF8

# Display summary
Write-Host ""
Write-Host "✅ Infrastructure export completed!" -ForegroundColor Green
Write-Host "📁 Export location: $exportDir" -ForegroundColor Blue
Write-Host ""
Write-Host "📋 Export Summary:" -ForegroundColor Blue
Write-Host "- Current Tenant: $($currentAccount.tenantId)" -ForegroundColor White
Write-Host "- Current Subscription: $($currentAccount.name)" -ForegroundColor White
Write-Host "- Resource Group: eShopCleverRG" -ForegroundColor White
Write-Host "- Total Resources: $($resources.Count)" -ForegroundColor White
Write-Host ""
Write-Host "📖 Next Steps:" -ForegroundColor Yellow
Write-Host "1. Review $exportDir/MIGRATION-SUMMARY.md" -ForegroundColor White
Write-Host "2. Prepare new Azure environment" -ForegroundColor White
Write-Host "3. Run .\execute-migration.ps1 for guided migration" -ForegroundColor White
Write-Host ""
Write-Host "⚠️ Important: Keep this export safe as backup during migration!" -ForegroundColor Red
