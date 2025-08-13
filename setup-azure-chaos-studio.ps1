# Azure Chaos Studio Setup Script
# This script creates Chaos Studio targets and experiments using Azure CLI

param(
    [Parameter(Mandatory=$false)]
    [string]$SubscriptionId = "d7d7369b-a14f-43bc-a564-b4a077d170a9",
    
    [Parameter(Mandatory=$false)]
    [string]$ResourceGroup = "eShopCleverRG",
    
    [Parameter(Mandatory=$false)]
    [string]$ClusterName = "eshopcleveraks"
)

Write-Host "🎯 Setting up Azure Chaos Studio for eShopOnWeb" -ForegroundColor Green
Write-Host "📋 Subscription: $SubscriptionId" -ForegroundColor Yellow
Write-Host "📋 Resource Group: $ResourceGroup" -ForegroundColor Yellow
Write-Host "📋 AKS Cluster: $ClusterName" -ForegroundColor Yellow

# Set the subscription
Write-Host "🔧 Setting Azure subscription..." -ForegroundColor Cyan
az account set --subscription $SubscriptionId

# Check if Chaos provider is registered
Write-Host "🔍 Checking Microsoft.Chaos provider registration..." -ForegroundColor Cyan
$providerStatus = az provider show --namespace Microsoft.Chaos --query "registrationState" -o tsv

if ($providerStatus -ne "Registered") {
    Write-Host "⚠️ Microsoft.Chaos provider is not registered. Status: $providerStatus" -ForegroundColor Yellow
    
    if ($providerStatus -eq "NotRegistered") {
        Write-Host "📝 Registering Microsoft.Chaos provider..." -ForegroundColor Cyan
        az provider register --namespace Microsoft.Chaos
    }
    
    Write-Host "⏳ Waiting for provider registration to complete..." -ForegroundColor Yellow
    do {
        Start-Sleep 30
        $providerStatus = az provider show --namespace Microsoft.Chaos --query "registrationState" -o tsv
        Write-Host "📊 Provider status: $providerStatus" -ForegroundColor Gray
    } while ($providerStatus -eq "Registering")
}

if ($providerStatus -eq "Registered") {
    Write-Host "✅ Microsoft.Chaos provider is registered" -ForegroundColor Green
} else {
    Write-Host "❌ Failed to register Microsoft.Chaos provider. Status: $providerStatus" -ForegroundColor Red
    exit 1
}

# Get AKS resource ID
Write-Host "🔍 Getting AKS cluster resource ID..." -ForegroundColor Cyan
$aksResourceId = "/subscriptions/$SubscriptionId/resourceGroups/$ResourceGroup/providers/Microsoft.ContainerService/managedClusters/$ClusterName"
Write-Host "📋 AKS Resource ID: $aksResourceId" -ForegroundColor Gray

# Create Chaos Studio target for AKS
Write-Host "🎯 Creating Chaos Studio target for AKS..." -ForegroundColor Cyan
$targetName = "Microsoft-AzureKubernetesServiceChaosMesh"
$targetUrl = "https://management.azure.com$aksResourceId/providers/Microsoft.Chaos/targets/$targetName" + "?api-version=2023-11-01"

$targetBody = @{
    properties = @{
        location = "eastus"
    }
} | ConvertTo-Json -Depth 3

try {
    $targetResult = az rest --method put --url $targetUrl --body $targetBody
    Write-Host "✅ Chaos Studio target created successfully" -ForegroundColor Green
    Write-Host "📋 Target: $($targetResult | ConvertFrom-Json | Select-Object -ExpandProperty name)" -ForegroundColor Gray
} catch {
    Write-Host "❌ Failed to create Chaos Studio target: $_" -ForegroundColor Red
    Write-Host "🔍 Checking if target already exists..." -ForegroundColor Yellow
    
    try {
        $existingTarget = az rest --method get --url $targetUrl
        Write-Host "✅ Chaos Studio target already exists" -ForegroundColor Green
    } catch {
        Write-Host "❌ Target does not exist and could not be created" -ForegroundColor Red
        exit 1
    }
}

# Create Pod Failure Experiment
Write-Host "🔥 Creating Pod Failure Chaos Experiment..." -ForegroundColor Red

$experimentName = "eshop-pod-failure-experiment"
$experimentUrl = "https://management.azure.com/subscriptions/$SubscriptionId/resourceGroups/$ResourceGroup/providers/Microsoft.Chaos/experiments/$experimentName" + "?api-version=2023-11-01"

$experimentBody = @{
    location = "eastus"
    identity = @{
        type = "SystemAssigned"
    }
    properties = @{
        selectors = @(
            @{
                name = "eshop-webmvc-selector"
                targets = @(
                    @{
                        id = "$aksResourceId/providers/Microsoft.Chaos/targets/$targetName"
                        type = "ChaosTarget"
                    }
                )
            }
        )
        steps = @(
            @{
                name = "Step 1"
                branches = @(
                    @{
                        name = "Branch 1"
                        actions = @(
                            @{
                                name = "urn:csci:microsoft:azureKubernetesServiceChaosMesh:podChaos/2.2"
                                type = "continuous"
                                duration = "PT5M"
                                parameters = @(
                                    @{
                                        key = "jsonSpec"
                                        value = '{"action":"pod-failure","duration":"60s","mode":"one","selector":{"labelSelectors":{"app":"eshop-webmvc"},"namespaces":["eshop"]}}'
                                    }
                                )
                                selectorid = "eshop-webmvc-selector"
                            }
                        )
                    }
                )
            }
        )
    }
} | ConvertTo-Json -Depth 10

try {
    $experimentResult = az rest --method put --url $experimentUrl --body $experimentBody
    Write-Host "✅ Pod Failure experiment created successfully" -ForegroundColor Green
    Write-Host "📋 Experiment: $experimentName" -ForegroundColor Gray
} catch {
    Write-Host "❌ Failed to create Pod Failure experiment: $_" -ForegroundColor Red
}

# Create CPU Stress Experiment
Write-Host "🔥 Creating CPU Stress Chaos Experiment..." -ForegroundColor Red

$cpuExperimentName = "eshop-cpu-stress-experiment"
$cpuExperimentUrl = "https://management.azure.com/subscriptions/$SubscriptionId/resourceGroups/$ResourceGroup/providers/Microsoft.Chaos/experiments/$cpuExperimentName" + "?api-version=2023-11-01"

$cpuExperimentBody = @{
    location = "eastus"
    identity = @{
        type = "SystemAssigned"
    }
    properties = @{
        selectors = @(
            @{
                name = "eshop-webmvc-cpu-selector"
                targets = @(
                    @{
                        id = "$aksResourceId/providers/Microsoft.Chaos/targets/$targetName"
                        type = "ChaosTarget"
                    }
                )
            }
        )
        steps = @(
            @{
                name = "Step 1"
                branches = @(
                    @{
                        name = "Branch 1"
                        actions = @(
                            @{
                                name = "urn:csci:microsoft:azureKubernetesServiceChaosMesh:stressChaos/2.2"
                                type = "continuous"
                                duration = "PT5M"
                                parameters = @(
                                    @{
                                        key = "jsonSpec"
                                        value = '{"duration":"300s","mode":"all","selector":{"labelSelectors":{"app":"eshop-webmvc"},"namespaces":["eshop"]},"stressors":{"cpu":{"load":80,"workers":2}}}'
                                    }
                                )
                                selectorid = "eshop-webmvc-cpu-selector"
                            }
                        )
                    }
                )
            }
        )
    }
} | ConvertTo-Json -Depth 10

try {
    $cpuExperimentResult = az rest --method put --url $cpuExperimentUrl --body $cpuExperimentBody
    Write-Host "✅ CPU Stress experiment created successfully" -ForegroundColor Green
    Write-Host "📋 Experiment: $cpuExperimentName" -ForegroundColor Gray
} catch {
    Write-Host "❌ Failed to create CPU Stress experiment: $_" -ForegroundColor Red
}

Write-Host "🎉 Azure Chaos Studio setup completed!" -ForegroundColor Green
Write-Host "🌐 You can now view your experiments in the Azure Portal:" -ForegroundColor Yellow
Write-Host "   https://portal.azure.com/#@$((az account show --query tenantId -o tsv))/resource/subscriptions/$SubscriptionId/resourceGroups/$ResourceGroup/providers/Microsoft.Chaos/experiments" -ForegroundColor Cyan

Write-Host "🚀 To run an experiment:" -ForegroundColor Yellow
Write-Host "   1. Go to Azure Portal > Chaos Studio" -ForegroundColor Gray
Write-Host "   2. Navigate to Experiments" -ForegroundColor Gray
Write-Host "   3. Select your experiment" -ForegroundColor Gray
Write-Host "   4. Click 'Start'" -ForegroundColor Gray
