# Create Azure Chaos Studio Experiments for Portal Management
# This script creates experiments that will be visible and manageable from Azure Portal

param(
    [Parameter(Mandatory=$false)]
    [string]$ResourceGroup = "eShopCleverRG",
    
    [Parameter(Mandatory=$false)]
    [string]$AksClusterName = "eshopcleveraks",
    
    [Parameter(Mandatory=$false)]
    [string]$Location = "eastus"
)

$ErrorActionPreference = "Stop"

Write-Host "🔥 Creating Azure Chaos Studio Experiments for Portal" -ForegroundColor Red
Write-Host "====================================================" -ForegroundColor Red

# Get subscription and cluster info
$subscriptionId = az account show --query id -o tsv
$aksResourceId = az aks show --resource-group $ResourceGroup --name $AksClusterName --query id -o tsv

Write-Host "📋 Configuration:" -ForegroundColor Yellow
Write-Host "  Subscription: $subscriptionId" -ForegroundColor White
Write-Host "  Resource Group: $ResourceGroup" -ForegroundColor White
Write-Host "  AKS Cluster: $AksClusterName" -ForegroundColor White
Write-Host "  AKS Resource ID: $aksResourceId" -ForegroundColor White

function Enable-ChaosTarget {
    Write-Host "`n🎯 Enabling Chaos Studio target..." -ForegroundColor Cyan
    
    # Register provider
    Write-Host "📋 Registering Microsoft.Chaos provider..." -ForegroundColor Yellow
    az provider register --namespace Microsoft.Chaos --wait --output none
    
    # Enable target using az rest with proper headers
    Write-Host "🎯 Enabling AKS cluster as chaos target..." -ForegroundColor Yellow
    $targetUrl = "https://management.azure.com$aksResourceId/providers/Microsoft.Chaos/targets/Microsoft-AzureKubernetesServiceChaosMesh?api-version=2024-01-01"
    
    az rest --method PUT --url $targetUrl --headers "Content-Type=application/json" --body '{"properties":{}}' --output none
    
    # Enable capabilities
    $capabilities = @("PodChaos-2.2", "StressChaos-2.2", "NetworkChaos-2.2", "IOChaos-2.2")
    
    foreach ($capability in $capabilities) {
        Write-Host "⚡ Enabling capability: $capability" -ForegroundColor Yellow
        $capUrl = "https://management.azure.com$aksResourceId/providers/Microsoft.Chaos/targets/Microsoft-AzureKubernetesServiceChaosMesh/capabilities/$capability" + "?api-version=2024-01-01"
        az rest --method PUT --url $capUrl --headers "Content-Type=application/json" --body '{"properties":{}}' --output none
    }
    
    Write-Host "✅ Chaos target enabled successfully!" -ForegroundColor Green
}

function Deploy-ChaosExperiment {
    param(
        [string]$ExperimentName,
        [string]$TemplateFile
    )
    
    Write-Host "🧪 Deploying experiment: $ExperimentName" -ForegroundColor Yellow
    
    try {
        # Deploy using ARM template
        $deployment = az deployment group create --resource-group $ResourceGroup --template-file $TemplateFile --parameters experimentName=$ExperimentName location=$Location aksClusterResourceId="$aksResourceId" --query properties.outputs --output json | ConvertFrom-Json
        
        if ($deployment.principalId.value) {
            Write-Host "🔐 Assigning permissions..." -ForegroundColor Yellow
            
            # Assign permissions
            az role assignment create --assignee $deployment.principalId.value --role "Reader" --scope "/subscriptions/$subscriptionId/resourceGroups/$ResourceGroup" --output none 2>$null
            az role assignment create --assignee $deployment.principalId.value --role "Azure Kubernetes Service Cluster User Role" --scope $aksResourceId --output none 2>$null
        }
        
        Write-Host "✅ Experiment deployed: $ExperimentName" -ForegroundColor Green
        
    } catch {
        Write-Warning "⚠️ Failed to deploy $ExperimentName : $($_.Exception.Message)"
    }
}

function Show-PortalAccess {
    Write-Host "`n🌍 Access Your Experiments in Azure Portal:" -ForegroundColor Green
    Write-Host "===========================================" -ForegroundColor Green
    
    Write-Host "`n1. 🔥 Direct Chaos Studio Link:" -ForegroundColor Yellow
    Write-Host "   https://portal.azure.com/#view/Microsoft_Azure_Chaos/ChaosStudio.MenuView/~/chaosExperiment" -ForegroundColor Cyan
    
    Write-Host "`n2. 📊 Resource Group View:" -ForegroundColor Yellow
    Write-Host "   https://portal.azure.com/#@/resource/subscriptions/$subscriptionId/resourceGroups/$ResourceGroup/overview" -ForegroundColor Cyan
    
    Write-Host "`n3. 🎮 How to Run Experiments:" -ForegroundColor Yellow
    Write-Host "   a) Click the Chaos Studio link above" -ForegroundColor White
    Write-Host "   b) Navigate to 'Experiments' section" -ForegroundColor White
    Write-Host "   c) Find your experiment (eshop-pod-failure-experiment)" -ForegroundColor White
    Write-Host "   d) Click on the experiment name" -ForegroundColor White
    Write-Host "   e) Click 'Start' to run the experiment" -ForegroundColor White
    Write-Host "   f) Monitor progress in real-time" -ForegroundColor White
    
    Write-Host "`n4. 📈 What You'll See:" -ForegroundColor Yellow
    Write-Host "   - Experiment execution status" -ForegroundColor White
    Write-Host "   - Real-time progress and logs" -ForegroundColor White
    Write-Host "   - Target health and impact" -ForegroundColor White
    Write-Host "   - Historical run data" -ForegroundColor White
    Write-Host "   - Integration with Azure Monitor" -ForegroundColor White
    
    Write-Host "`n5. 🔗 Additional Resources:" -ForegroundColor Yellow
    Write-Host "   - Container Insights: Monitor pod impact" -ForegroundColor White
    Write-Host "   - Azure Monitor: View detailed metrics" -ForegroundColor White
    Write-Host "   - Activity Log: Track experiment events" -ForegroundColor White
}

# Main execution
try {
    # Step 1: Enable chaos target
    Enable-ChaosTarget
    
    # Step 2: Deploy experiment using ARM template
    Write-Host "`n🧪 Creating chaos experiments..." -ForegroundColor Green
    Deploy-ChaosExperiment -ExperimentName "eshop-pod-failure-experiment" -TemplateFile "chaos-experiment-template.json"
    
    # Step 3: List created experiments
    Write-Host "`n📋 Listing created experiments..." -ForegroundColor Yellow
    $experiments = az resource list --resource-group $ResourceGroup --resource-type "Microsoft.Chaos/experiments" --query "[].{Name:name, Location:location, State:properties.provisioningState}" --output table
    
    if ($experiments) {
        Write-Host "✅ Successfully created experiments:" -ForegroundColor Green
        Write-Host $experiments
    } else {
        Write-Host "⚠️ No experiments found. There might have been an issue with creation." -ForegroundColor Yellow
    }
    
    # Step 4: Show portal access information
    Show-PortalAccess
    
    Write-Host "`n✅ Azure Chaos Studio setup complete!" -ForegroundColor Green
    Write-Host "🚀 Your experiments are now ready to run from the Azure Portal!" -ForegroundColor Cyan
    
} catch {
    Write-Host "❌ Error: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}
