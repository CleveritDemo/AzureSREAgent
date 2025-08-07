# Monitor Chaos Experiments Dashboard Access Script
# This script helps you access both Chaos Mesh dashboard and Azure Portal monitoring

param(
    [Parameter(Mandatory=$false)]
    [switch]$OpenDashboards,
    
    [Parameter(Mandatory=$false)]
    [switch]$RunExperiments,
    
    [Parameter(Mandatory=$false)]
    [switch]$StopExperiments
)

$ErrorActionPreference = "Stop"

Write-Host "🔥 Chaos Engineering Monitoring Dashboard" -ForegroundColor Red
Write-Host "==========================================" -ForegroundColor Red

function Start-ChaosDashboard {
    Write-Host "🌐 Starting Chaos Mesh Dashboard..." -ForegroundColor Yellow
    
    # Check if port-forward is already running
    $existingProcess = Get-Process -Name "kubectl" -ErrorAction SilentlyContinue | Where-Object { $_.CommandLine -like "*port-forward*chaos-dashboard*" }
    
    if (-not $existingProcess) {
        Write-Host "🚀 Starting port-forward for Chaos Dashboard..." -ForegroundColor Green
        Start-Process -FilePath "kubectl" -ArgumentList "port-forward", "-n", "chaos-mesh", "svc/chaos-dashboard", "2333:2333" -WindowStyle Hidden
        Start-Sleep -Seconds 3
    } else {
        Write-Host "✅ Chaos Dashboard port-forward already running" -ForegroundColor Green
    }
    
    Write-Host "🌍 Chaos Mesh Dashboard: http://localhost:2333" -ForegroundColor Cyan
}

function Show-AzurePortalLinks {
    Write-Host "🌍 Azure Portal Monitoring Links:" -ForegroundColor Yellow
    Write-Host "==================================" -ForegroundColor Yellow
    
    # Get resource group and subscription info
    try {
        $subscription = az account show --query id -o tsv
        $resourceGroup = "eShopCleverRG"
        
        Write-Host "📊 Azure Monitor - AKS Cluster:" -ForegroundColor Cyan
        Write-Host "https://portal.azure.com/#@/resource/subscriptions/$subscription/resourceGroups/$resourceGroup/providers/Microsoft.ContainerService/managedClusters/eshopcleveraks/overview" -ForegroundColor White
        
        Write-Host ""
        Write-Host "📈 Azure Monitor - Metrics:" -ForegroundColor Cyan
        Write-Host "https://portal.azure.com/#@/resource/subscriptions/$subscription/resourceGroups/$resourceGroup/providers/Microsoft.ContainerService/managedClusters/eshopcleveraks/metrics" -ForegroundColor White
        
        Write-Host ""
        Write-Host "📋 Azure Monitor - Logs:" -ForegroundColor Cyan
        Write-Host "https://portal.azure.com/#@/resource/subscriptions/$subscription/resourceGroups/$resourceGroup/providers/Microsoft.ContainerService/managedClusters/eshopcleveraks/logs" -ForegroundColor White
        
        Write-Host ""
        Write-Host "🔍 Azure Monitor - Insights:" -ForegroundColor Cyan
        Write-Host "https://portal.azure.com/#@/resource/subscriptions/$subscription/resourceGroups/$resourceGroup/providers/Microsoft.ContainerService/managedClusters/eshopcleveraks/insights" -ForegroundColor White
        
        Write-Host ""
        Write-Host "🚨 Azure Monitor - Alerts:" -ForegroundColor Cyan
        Write-Host "https://portal.azure.com/#@/resource/subscriptions/$subscription/resourceGroups/$resourceGroup/providers/Microsoft.ContainerService/managedClusters/eshopcleveraks/alerts" -ForegroundColor White
        
        Write-Host ""
        Write-Host "🔥 Chaos Studio (if available):" -ForegroundColor Cyan
        Write-Host "https://portal.azure.com/#view/Microsoft_Azure_ChaosStudio/ChaosStudioMenuBlade/~/overview" -ForegroundColor White
        
    } catch {
        Write-Warning "Could not get Azure subscription info. Make sure you're logged in with 'az login'"
    }
}

function Show-CurrentExperiments {
    Write-Host "🧪 Current Chaos Experiments:" -ForegroundColor Yellow
    Write-Host "==============================" -ForegroundColor Yellow
    
    try {
        Write-Host "📊 Pod Chaos Experiments:" -ForegroundColor Green
        kubectl get podchaos -A -o custom-columns=NAMESPACE:.metadata.namespace,NAME:.metadata.name,ACTION:.spec.action,DURATION:.spec.duration,AGE:.metadata.creationTimestamp
        
        Write-Host ""
        Write-Host "🌐 Network Chaos Experiments:" -ForegroundColor Green
        kubectl get networkchaos -A -o custom-columns=NAMESPACE:.metadata.namespace,NAME:.metadata.name,ACTION:.spec.action,DURATION:.spec.duration,AGE:.metadata.creationTimestamp
        
        Write-Host ""
        Write-Host "💾 Stress Chaos Experiments:" -ForegroundColor Green
        kubectl get stresschaos -A -o custom-columns=NAMESPACE:.metadata.namespace,NAME:.metadata.name,DURATION:.spec.duration,AGE:.metadata.creationTimestamp
        
        Write-Host ""
        Write-Host "📈 Real-time Pod Status:" -ForegroundColor Green
        kubectl get pods -n eshop -o wide
        
    } catch {
        Write-Warning "Could not retrieve chaos experiments. Make sure kubectl is configured."
    }
}

function Start-NewExperiments {
    Write-Host "🚀 Starting New Chaos Experiments..." -ForegroundColor Red
    
    Write-Host "🔥 Creating Severe Pod Chaos..." -ForegroundColor Yellow
    kubectl apply -f "k8s/severe-pod-chaos.yaml"
    
    Write-Host "💻 Creating CPU Stress..." -ForegroundColor Yellow
    kubectl apply -f "k8s/cpu-stress-chaos.yaml"
    
    Write-Host "🌐 Creating Network Delay..." -ForegroundColor Yellow
    kubectl apply -f "k8s/network-delay-chaos.yaml"
    
    Write-Host "✅ Experiments started! Monitor them in the dashboards." -ForegroundColor Green
}

function Stop-AllExperiments {
    Write-Host "🛑 Stopping All Chaos Experiments..." -ForegroundColor Red
    
    Write-Host "🧹 Cleaning up experiments..." -ForegroundColor Yellow
    kubectl delete podchaos,networkchaos,stresschaos -A --all
    
    Write-Host "✅ All experiments stopped." -ForegroundColor Green
}

function Show-MonitoringCommands {
    Write-Host "📊 Real-time Monitoring Commands:" -ForegroundColor Yellow
    Write-Host "==================================" -ForegroundColor Yellow
    
    Write-Host "🔍 Watch Pod Status:" -ForegroundColor Cyan
    Write-Host "kubectl get pods -n eshop --watch" -ForegroundColor White
    
    Write-Host ""
    Write-Host "📈 Watch Resource Usage:" -ForegroundColor Cyan
    Write-Host "kubectl top pods -n eshop --containers" -ForegroundColor White
    
    Write-Host ""
    Write-Host "📋 View Logs:" -ForegroundColor Cyan
    Write-Host "kubectl logs -f deployment/webmvc -n eshop" -ForegroundColor White
    
    Write-Host ""
    Write-Host "🔥 Watch Chaos Experiments:" -ForegroundColor Cyan
    Write-Host "kubectl get podchaos,networkchaos,stresschaos -A --watch" -ForegroundColor White
    
    Write-Host ""
    Write-Host "📊 Monitor Events:" -ForegroundColor Cyan
    Write-Host "kubectl get events -n eshop --sort-by='.lastTimestamp'" -ForegroundColor White
}

# Main execution
try {
    if ($OpenDashboards) {
        Start-ChaosDashboard
        Start-Sleep -Seconds 2
        Show-AzurePortalLinks
        
        # Open browsers
        Start-Process "http://localhost:2333"  # Chaos Mesh Dashboard
        
        Write-Host ""
        Write-Host "🎯 Dashboards opened! Use the Azure Portal links above for cloud monitoring." -ForegroundColor Green
        
    } elseif ($RunExperiments) {
        Start-NewExperiments
        Start-Sleep -Seconds 5
        Show-CurrentExperiments
        
    } elseif ($StopExperiments) {
        Stop-AllExperiments
        
    } else {
        # Default: Show current status and instructions
        Show-CurrentExperiments
        Write-Host ""
        Start-ChaosDashboard
        Write-Host ""
        Show-AzurePortalLinks
        Write-Host ""
        Show-MonitoringCommands
        
        Write-Host ""
        Write-Host "🎯 Usage Examples:" -ForegroundColor Green
        Write-Host "==================" -ForegroundColor Green
        Write-Host ".\monitor-chaos-experiments.ps1 -OpenDashboards    # Open all monitoring dashboards" -ForegroundColor White
        Write-Host ".\monitor-chaos-experiments.ps1 -RunExperiments    # Start new chaos experiments" -ForegroundColor White
        Write-Host ".\monitor-chaos-experiments.ps1 -StopExperiments   # Stop all running experiments" -ForegroundColor White
        Write-Host ".\monitor-chaos-experiments.ps1                   # Show current status" -ForegroundColor White
    }
    
} catch {
    Write-Host "❌ Error: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}
