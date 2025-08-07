# Azure Chaos Studio Setup Script for AKS
# This script sets up Chaos Studio and creates experiments visible in Azure Portal

param(
    [Parameter(Mandatory=$false)]
    [string]$ResourceGroup = "eShopCleverRG",
    
    [Parameter(Mandatory=$false)]
    [string]$AksClusterName = "eshopcleveraks",
    
    [Parameter(Mandatory=$false)]
    [string]$Location = "eastus",
    
    [Parameter(Mandatory=$false)]
    [switch]$CreateTargets,
    
    [Parameter(Mandatory=$false)]
    [switch]$CreateExperiments,
    
    [Parameter(Mandatory=$false)]
    [switch]$ListExperiments,
    
    [Parameter(Mandatory=$false)]
    [switch]$All
)

$ErrorActionPreference = "Stop"

Write-Host "🔥 Azure Chaos Studio Setup for Portal Integration" -ForegroundColor Red
Write-Host "=================================================" -ForegroundColor Red

# Get subscription ID dynamically
$subscriptionId = az account show --query id -o tsv
if (-not $subscriptionId) {
    Write-Error "❌ Not logged in to Azure. Run 'az login' first."
}

Write-Host "📋 Configuration:" -ForegroundColor Yellow
Write-Host "  Resource Group: $ResourceGroup" -ForegroundColor White
Write-Host "  AKS Cluster: $AksClusterName" -ForegroundColor White
Write-Host "  Location: $Location" -ForegroundColor White
Write-Host "  Subscription: $subscriptionId" -ForegroundColor White

function Enable-ChaosStudioTargets {
    Write-Host "`n🎯 Step 1: Setting up Chaos Studio targets..." -ForegroundColor Cyan
    
    # Enable Chaos Studio provider
    Write-Host "🔧 Registering Microsoft.Chaos provider..." -ForegroundColor Yellow
    az provider register --namespace Microsoft.Chaos --output none
    
    # Get AKS resource ID
    $aksResourceId = "/subscriptions/$subscriptionId/resourceGroups/$ResourceGroup/providers/Microsoft.ContainerService/managedClusters/$AksClusterName"
    Write-Host "✅ AKS Resource ID: $aksResourceId" -ForegroundColor Green
    
    # Enable the target
    Write-Host "🎯 Enabling AKS as Chaos Studio target..." -ForegroundColor Yellow
    az rest --method put --url "https://management.azure.com$aksResourceId/providers/Microsoft.Chaos/targets/Microsoft-AzureKubernetesServiceChaosMesh?api-version=2024-01-01" --body '{
      "properties": {}
    }' --output none
    
    # Enable capabilities
    $capabilities = @(
        "PodChaos-2.2",
        "StressChaos-2.2", 
        "NetworkChaos-2.2",
        "IOChaos-2.2",
        "HTTPChaos-2.2"
    )
    
    Write-Host "⚡ Enabling chaos capabilities..." -ForegroundColor Yellow
    foreach ($capability in $capabilities) {
        Write-Host "  - Enabling $capability" -ForegroundColor White
        az rest --method put --url "https://management.azure.com$aksResourceId/providers/Microsoft.Chaos/targets/Microsoft-AzureKubernetesServiceChaosMesh/capabilities/$capability?api-version=2024-01-01" --body '{
          "properties": {}
        }' --output none
    }
    
    Write-Host "✅ Chaos Studio targets configured successfully!" -ForegroundColor Green
}

function New-ChaosExperiment {
    param(
        [string]$ExperimentName,
        [string]$Description,
        [string]$ActionType,
        [string]$JsonSpec,
        [string]$Duration = "PT10M"
    )
    
    Write-Host "🧪 Creating experiment: $ExperimentName" -ForegroundColor Yellow
    
    $aksResourceId = "/subscriptions/$subscriptionId/resourceGroups/$ResourceGroup/providers/Microsoft.ContainerService/managedClusters/$AksClusterName"
    
    $experimentBody = @{
        location = $Location
        identity = @{
            type = "SystemAssigned"
        }
        properties = @{
            selectors = @(
                @{
                    id = "eshop-targets"
                    type = "List"
                    targets = @(
                        @{
                            type = "ChaosTarget"
                            id = "$aksResourceId/providers/Microsoft.Chaos/targets/Microsoft-AzureKubernetesServiceChaosMesh"
                        }
                    )
                }
            )
            steps = @(
                @{
                    name = "ChaosStep"
                    branches = @(
                        @{
                            name = "ChaosBranch"
                            actions = @(
                                @{
                                    type = $ActionType
                                    name = "ChaosAction"
                                    parameters = @(
                                        @{
                                            key = "jsonSpec"
                                            value = $JsonSpec
                                        }
                                    )
                                    duration = $Duration
                                    selectorId = "eshop-targets"
                                }
                            )
                        }
                    )
                }
            )
        }
    } | ConvertTo-Json -Depth 15
    
    try {
        $experimentUrl = "https://management.azure.com/subscriptions/$subscriptionId/resourceGroups/$ResourceGroup/providers/Microsoft.Chaos/experiments/$ExperimentName" + "?api-version=2024-01-01"
        
        az rest --method PUT --url $experimentUrl --body $experimentBody --output none
        Write-Host "✅ Created experiment: $ExperimentName" -ForegroundColor Green
        
        # Get and assign permissions
        Start-Sleep -Seconds 3
        $experiment = az rest --method GET --url $experimentUrl | ConvertFrom-Json
        
        if ($experiment.identity.principalId) {
            Write-Host "🔐 Assigning permissions to experiment..." -ForegroundColor Yellow
            
            # Assign Reader role on resource group
            az role assignment create --assignee $experiment.identity.principalId --role "Reader" --scope "/subscriptions/$subscriptionId/resourceGroups/$ResourceGroup" --output none 2>$null
            
            # Assign AKS Cluster User role
            az role assignment create --assignee $experiment.identity.principalId --role "Azure Kubernetes Service Cluster User Role" --scope $aksResourceId --output none 2>$null
            
            Write-Host "✅ Permissions assigned" -ForegroundColor Green
        }
        
    } catch {
        Write-Warning "⚠️ Could not create experiment $ExperimentName : $($_.Exception.Message)"
    }
}

function New-PodFailureExperiment {
    $jsonSpec = @"
{
  "mode": "one",
  "selector": {
    "namespaces": ["eshop"],
    "labelSelectors": {
      "app": "webmvc"
    }
  },
  "action": "pod-failure",
  "duration": "60s"
}
"@
    
    New-ChaosExperiment -ExperimentName "eshop-pod-failure" -Description "Pod failure experiment for eShop WebMVC" -ActionType "urn:csci:microsoft:azureKubernetesServiceChaosMesh:podChaos/2.2" -JsonSpec $jsonSpec -Duration "PT5M"
}

function New-CPUStressExperiment {
    $jsonSpec = @"
{
  "mode": "one",
  "selector": {
    "namespaces": ["eshop"],
    "labelSelectors": {
      "app": "webmvc"
    }
  },
  "duration": "180s",
  "stressors": {
    "cpu": {
      "workers": 2,
      "load": 80
    }
  }
}
"@
    
    New-ChaosExperiment -ExperimentName "eshop-cpu-stress" -Description "CPU stress experiment for eShop WebMVC" -ActionType "urn:csci:microsoft:azureKubernetesServiceChaosMesh:stressChaos/2.2" -JsonSpec $jsonSpec -Duration "PT8M"
}

function New-NetworkDelayExperiment {
    $jsonSpec = @"
{
  "mode": "one",
  "selector": {
    "namespaces": ["eshop"],
    "labelSelectors": {
      "app": "webmvc"
    }
  },
  "action": "delay",
  "duration": "120s",
  "delay": {
    "latency": "200ms",
    "correlation": "0",
    "jitter": "10ms"
  }
}
"@
    
    New-ChaosExperiment -ExperimentName "eshop-network-delay" -Description "Network delay experiment for eShop WebMVC" -ActionType "urn:csci:microsoft:azureKubernetesServiceChaosMesh:networkChaos/2.2" -JsonSpec $jsonSpec -Duration "PT6M"
}

function New-MemoryStressExperiment {
    $jsonSpec = @"
{
  "mode": "one",
  "selector": {
    "namespaces": ["eshop"],
    "labelSelectors": {
      "app": "publicapi"
    }
  },
  "duration": "240s",
  "stressors": {
    "memory": {
      "workers": 1,
      "size": "512MB"
    }
  }
}
"@
    
    New-ChaosExperiment -ExperimentName "eshop-memory-stress" -Description "Memory stress experiment for eShop PublicAPI" -ActionType "urn:csci:microsoft:azureKubernetesServiceChaosMesh:stressChaos/2.2" -JsonSpec $jsonSpec -Duration "PT7M"
}

function Get-ChaosExperiments {
    Write-Host "`n📋 Listing Azure Chaos Studio experiments..." -ForegroundColor Yellow
    
    try {
        $experiments = az resource list --resource-group $ResourceGroup --resource-type "Microsoft.Chaos/experiments" --query "[].{Name:name, Location:location, State:properties.provisioningState}" --output table
        
        if ($experiments) {
            Write-Host "📊 Found experiments in resource group '$ResourceGroup':" -ForegroundColor Green
            Write-Host $experiments
        } else {
            Write-Host "📭 No experiments found in resource group: $ResourceGroup" -ForegroundColor Yellow
        }
        
    } catch {
        Write-Warning "⚠️ Could not list experiments: $($_.Exception.Message)"
    }
}

function Show-PortalLinks {
    Write-Host "`n🌍 Azure Portal Access Links:" -ForegroundColor Green
    Write-Host "=============================" -ForegroundColor Green
    
    Write-Host "`n1. 🔥 Chaos Studio Portal:" -ForegroundColor Yellow
    Write-Host "   https://portal.azure.com/#view/Microsoft_Azure_Chaos/ChaosStudio.MenuView/~/chaosExperiment" -ForegroundColor White
    
    Write-Host "`n2. 📊 Resource Group Overview:" -ForegroundColor Yellow
    Write-Host "   https://portal.azure.com/#@/resource/subscriptions/$subscriptionId/resourceGroups/$ResourceGroup/overview" -ForegroundColor White
    
    Write-Host "`n3. 🎮 How to Run Experiments from Portal:" -ForegroundColor Yellow
    Write-Host "   a) Navigate to Chaos Studio → Experiments" -ForegroundColor White
    Write-Host "   b) Select your experiment (eshop-pod-failure, eshop-cpu-stress, etc.)" -ForegroundColor White
    Write-Host "   c) Click 'Start' button to run the experiment" -ForegroundColor White
    Write-Host "   d) Monitor progress in real-time" -ForegroundColor White
    Write-Host "   e) View results and logs after completion" -ForegroundColor White
    
    Write-Host "`n4. 📈 Monitoring Integration:" -ForegroundColor Yellow
    Write-Host "   - Experiments integrate with Azure Monitor" -ForegroundColor White
    Write-Host "   - Use Container Insights for detailed pod metrics" -ForegroundColor White
    Write-Host "   - Set up alerts for experiment failures" -ForegroundColor White
    Write-Host "   - View execution history and results" -ForegroundColor White
}

# Main execution logic

try {
    if ($All) {
        Write-Host "`n🚀 Running complete Chaos Studio setup..." -ForegroundColor Green
        Enable-ChaosStudioTargets
        Start-Sleep -Seconds 5
        
        Write-Host "`n🧪 Creating all experiments..." -ForegroundColor Green
        New-PodFailureExperiment
        Start-Sleep -Seconds 3
        New-CPUStressExperiment
        Start-Sleep -Seconds 3
        New-NetworkDelayExperiment
        Start-Sleep -Seconds 3
        New-MemoryStressExperiment
        Start-Sleep -Seconds 3
        
        Get-ChaosExperiments
        
    } elseif ($CreateTargets) {
        Enable-ChaosStudioTargets
        
    } elseif ($CreateExperiments) {
        Write-Host "`n🧪 Creating chaos experiments..." -ForegroundColor Green
        New-PodFailureExperiment
        Start-Sleep -Seconds 3
        New-CPUStressExperiment
        Start-Sleep -Seconds 3
        New-NetworkDelayExperiment
        Start-Sleep -Seconds 3
        New-MemoryStressExperiment
        Start-Sleep -Seconds 3
        
        Get-ChaosExperiments
        
    } elseif ($ListExperiments) {
        Get-ChaosExperiments
        
    } else {
        Write-Host "`n🎯 Azure Chaos Studio Setup Options:" -ForegroundColor Green
        Write-Host "====================================" -ForegroundColor Green
        Write-Host ""
        Write-Host "Complete setup (recommended):" -ForegroundColor Yellow
        Write-Host "  .\setup-chaos-studio.ps1 -All" -ForegroundColor White
        Write-Host ""
        Write-Host "Step-by-step setup:" -ForegroundColor Yellow
        Write-Host "  .\setup-chaos-studio.ps1 -CreateTargets" -ForegroundColor White
        Write-Host "  .\setup-chaos-studio.ps1 -CreateExperiments" -ForegroundColor White
        Write-Host ""
        Write-Host "List existing experiments:" -ForegroundColor Yellow
        Write-Host "  .\setup-chaos-studio.ps1 -ListExperiments" -ForegroundColor White
    }
    
    Show-PortalLinks
    
    Write-Host "`n✅ Setup completed successfully!" -ForegroundColor Green
    Write-Host "🌍 Navigate to the Azure Portal links above to run your experiments!" -ForegroundColor Cyan
    
} catch {
    Write-Host "❌ Error: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Stack trace: $($_.ScriptStackTrace)" -ForegroundColor Red
    exit 1
}
