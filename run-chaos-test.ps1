# Azure Chaos Studio AKS Testing Script
# This script runs chaos experiments and monitors the Azure SRE Agent response

param(
    [Parameter(Mandatory=$false)]
    [ValidateSet("pod-failure", "cpu-stress", "network-delay", "all-chaos")]
    [string]$ExperimentType = "pod-failure",
    
    [Parameter(Mandatory=$false)]
    [int]$Duration = 120
)

Write-Host "🎯 Starting Azure Chaos Studio Testing for eShopOnWeb" -ForegroundColor Green
Write-Host "📋 Experiment Type: $ExperimentType" -ForegroundColor Yellow
Write-Host "⏱️ Duration: $Duration seconds" -ForegroundColor Yellow

# Function to check application health
function Test-ApplicationHealth {
    Write-Host "`n🔍 Testing application health..." -ForegroundColor Cyan
    try {
        $response = Invoke-WebRequest -Uri "http://20.253.117.38" -Method Head -TimeoutSec 10
        if ($response.StatusCode -eq 200) {
            Write-Host "✅ Application is healthy (HTTP $($response.StatusCode))" -ForegroundColor Green
            return $true
        }
    }
    catch {
        Write-Host "❌ Application health check failed: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

# Function to monitor pods
function Monitor-Pods {
    Write-Host "`n📊 Current pod status:" -ForegroundColor Cyan
    kubectl get pods -n eshop
}

# Function to check chaos mesh status
function Monitor-ChaosExperiments {
    Write-Host "`n⚡ Active chaos experiments:" -ForegroundColor Cyan
    kubectl get podchaos,stresschaos,networkchaos -n eshop
}

# Pre-experiment baseline
Write-Host "`n📊 BASELINE - Before Chaos Experiment" -ForegroundColor Magenta
Monitor-Pods
Test-ApplicationHealth

# Run the selected experiment
switch ($ExperimentType) {
    "pod-failure" {
        Write-Host "`n💥 Starting Pod Failure Chaos..." -ForegroundColor Red
        kubectl apply -f k8s/severe-pod-chaos.yaml
        $experimentName = "eshop-severe-chaos"
        $experimentType = "podchaos"
    }
    "cpu-stress" {
        Write-Host "`n🔥 Starting CPU Stress Chaos..." -ForegroundColor Red
        kubectl apply -f k8s/cpu-stress-chaos.yaml
        $experimentName = "eshop-cpu-stress"
        $experimentType = "stresschaos"
    }
    "network-delay" {
        Write-Host "`n🌐 Starting Network Delay Chaos..." -ForegroundColor Red
        kubectl apply -f k8s/network-delay-chaos.yaml
        $experimentName = "eshop-network-delay"
        $experimentType = "networkchaos"
    }
    "all-chaos" {
        Write-Host "`n💀 Starting ALL CHAOS EXPERIMENTS..." -ForegroundColor Red
        kubectl apply -f k8s/severe-pod-chaos.yaml
        kubectl apply -f k8s/cpu-stress-chaos.yaml
        kubectl apply -f k8s/network-delay-chaos.yaml
        $experimentName = "all"
        $experimentType = "all"
    }
}

Write-Host "`n⏰ Waiting 30 seconds for chaos to take effect..." -ForegroundColor Yellow
Start-Sleep -Seconds 30

# Monitor during experiment
Write-Host "`n📊 DURING CHAOS EXPERIMENT" -ForegroundColor Magenta
Monitor-Pods
Monitor-ChaosExperiments
Test-ApplicationHealth

# Monitor for the duration
$monitorDuration = $Duration - 30
$intervalSeconds = 30
$iterations = [math]::Ceiling($monitorDuration / $intervalSeconds)

for ($i = 1; $i -le $iterations; $i++) {
    Write-Host "`n⏰ Monitoring iteration $i/$iterations (${intervalSeconds}s interval)" -ForegroundColor Yellow
    Start-Sleep -Seconds $intervalSeconds
    
    Write-Host "`n📊 Health Check #$i" -ForegroundColor Cyan
    Monitor-Pods
    $isHealthy = Test-ApplicationHealth
    
    if (-not $isHealthy) {
        Write-Host "🚨 APPLICATION OUTAGE DETECTED!" -ForegroundColor Red
        Write-Host "   This is when Azure SRE Agent should kick in..." -ForegroundColor Yellow
    }
}

# Cleanup experiments
Write-Host "`n🧹 Cleaning up chaos experiments..." -ForegroundColor Yellow
if ($ExperimentType -eq "all-chaos") {
    kubectl delete podchaos eshop-severe-chaos -n eshop --ignore-not-found=true
    kubectl delete stresschaos eshop-cpu-stress -n eshop --ignore-not-found=true
    kubectl delete networkchaos eshop-network-delay -n eshop --ignore-not-found=true
} else {
    kubectl delete $experimentType $experimentName -n eshop --ignore-not-found=true
}

# Wait for recovery
Write-Host "`n⏰ Waiting 60 seconds for recovery..." -ForegroundColor Yellow
Start-Sleep -Seconds 60

# Post-experiment recovery check
Write-Host "`n📊 POST-EXPERIMENT - After Recovery" -ForegroundColor Magenta
Monitor-Pods
Test-ApplicationHealth

Write-Host "`n✅ Chaos experiment completed!" -ForegroundColor Green
Write-Host "`n📋 What to check in Azure SRE Agent:" -ForegroundColor Yellow
Write-Host "   1. Navigate to Azure Monitor" -ForegroundColor White
Write-Host "   2. Check for alerts and incidents" -ForegroundColor White
Write-Host "   3. Review SRE Agent recommendations" -ForegroundColor White
Write-Host "   4. Look for automated remediation actions" -ForegroundColor White
Write-Host "`n🌐 Azure Portal: https://portal.azure.com/#view/Microsoft_Azure_Monitoring/AzureMonitoringBrowseBlade" -ForegroundColor Cyan
