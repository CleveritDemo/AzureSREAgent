# Azure Chaos Studio Setup Script for AKS
# This script sets up Chaos Studio and enables chaos experiments on your AKS cluster

Write-Host "🎯 Setting up Azure Chaos Studio for AKS Chaos Experiments" -ForegroundColor Green

# Variables
$resourceGroup = "eShopCleverRG"
$aksClusterName = "eshopcleveraks" 
$location = "East US"
$subscriptionId = "5f62fee3-b00a-44d2-86e5-5cf130b28b5d"

Write-Host "📋 Configuration:" -ForegroundColor Yellow
Write-Host "  Resource Group: $resourceGroup"
Write-Host "  AKS Cluster: $aksClusterName"
Write-Host "  Location: $location"
Write-Host "  Subscription: $subscriptionId"

# Step 1: Enable Chaos Studio provider
Write-Host "`n🔧 Step 1: Enabling Chaos Studio resource provider..." -ForegroundColor Cyan
az provider register --namespace Microsoft.Chaos

# Step 2: Onboard the AKS cluster as a Chaos Studio target
Write-Host "`n🎯 Step 2: Onboarding AKS cluster to Chaos Studio..." -ForegroundColor Cyan
$aksResourceId = "/subscriptions/$subscriptionId/resourceGroups/$resourceGroup/providers/Microsoft.ContainerService/managedClusters/$aksClusterName"

# Enable the target
az rest --method put --url "https://management.azure.com$aksResourceId/providers/Microsoft.Chaos/targets/Microsoft-AzureKubernetesServiceChaosMesh?api-version=2024-01-01" --body '{
  "properties": {}
}'

# Step 3: Enable capabilities on the target
Write-Host "`n⚡ Step 3: Enabling chaos capabilities..." -ForegroundColor Cyan

# Enable Pod Chaos capability
az rest --method put --url "https://management.azure.com$aksResourceId/providers/Microsoft.Chaos/targets/Microsoft-AzureKubernetesServiceChaosMesh/capabilities/PodChaos-2.2?api-version=2024-01-01" --body '{
  "properties": {}
}'

# Enable Stress Chaos capability  
az rest --method put --url "https://management.azure.com$aksResourceId/providers/Microsoft.Chaos/targets/Microsoft-AzureKubernetesServiceChaosMesh/capabilities/StressChaos-2.2?api-version=2024-01-01" --body '{
  "properties": {}
}'

# Enable Network Chaos capability
az rest --method put --url "https://management.azure.com$aksResourceId/providers/Microsoft.Chaos/targets/Microsoft-AzureKubernetesServiceChaosMesh/capabilities/NetworkChaos-2.2?api-version=2024-01-01" --body '{
  "properties": {}
}'

# Enable IO Chaos capability
az rest --method put --url "https://management.azure.com$aksResourceId/providers/Microsoft.Chaos/targets/Microsoft-AzureKubernetesServiceChaosMesh/capabilities/IOChaos-2.2?api-version=2024-01-01" --body '{
  "properties": {}
}'

Write-Host "`n✅ Chaos Studio setup completed!" -ForegroundColor Green
Write-Host "`n📋 Next steps:" -ForegroundColor Yellow
Write-Host "  1. Create chaos experiments in Azure Portal"
Write-Host "  2. Grant experiment permissions to AKS cluster"  
Write-Host "  3. Run experiments to test resilience"
Write-Host "`n🌐 Access Chaos Studio: https://portal.azure.com/#view/Microsoft_Azure_Chaos/ChaosStudioMenuBlade" -ForegroundColor Cyan
