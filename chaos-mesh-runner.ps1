# Chaos Engineering Test Runner with Chaos Mesh
# This script helps run chaos experiments locally using Chaos Mesh

param(
    [Parameter(Mandatory=$true)]
    [ValidateSet("pod-failure", "cpu-stress", "network-delay", "all")]
    [string]$ExperimentType,
    
    [Parameter(Mandatory=$false)]
    [string]$Duration = "60s"
)

Write-Host "🔥 Starting Chaos Engineering Tests with Chaos Mesh..." -ForegroundColor Red
Write-Host "Experiment Type: $ExperimentType" -ForegroundColor Yellow
Write-Host "Duration: $Duration" -ForegroundColor Yellow

# Function to check application health
function Test-ApplicationHealth {
    Write-Host "🔍 Checking application health..." -ForegroundColor Cyan
    
    kubectl get pods -n eshop
    
    $webmvcPods = kubectl get pods -n eshop -l app=eshop-webmvc -o jsonpath='{.items[*].status.phase}'
    $apiPods = kubectl get pods -n eshop -l app=eshop-publicapi -o jsonpath='{.items[*].status.phase}'
    
    if ($webmvcPods -contains "Running" -and $apiPods -contains "Running") {
        Write-Host "✅ Application is healthy" -ForegroundColor Green
        return $true
    } else {
        Write-Host "❌ Application is not healthy" -ForegroundColor Red
        return $false
    }
}

# Function to run pod failure experiment
function Start-PodFailureExperiment {
    Write-Host "🔥 Running Pod Failure Experiment..." -ForegroundColor Red
    
    kubectl apply -f k8s/pod-chaos-experiment.yaml
    Start-Sleep 5
    
    Write-Host "Monitoring pod chaos experiment..."
    kubectl get podchaos -n eshop
    kubectl describe podchaos eshop-pod-chaos -n eshop
    
    Write-Host "Waiting for experiment to complete..."
    Start-Sleep 70
    
    kubectl delete podchaos eshop-pod-chaos -n eshop
    Write-Host "✅ Pod failure experiment completed" -ForegroundColor Green
}

# Function to run CPU stress experiment
function Start-CpuStressExperiment {
    Write-Host "🔥 Running CPU Stress Experiment..." -ForegroundColor Red
    
    kubectl apply -f k8s/cpu-stress-chaos.yaml
    Start-Sleep 5
    
    Write-Host "Monitoring CPU stress experiment..."
    kubectl get stresschaos -n eshop
    kubectl describe stresschaos eshop-cpu-stress -n eshop
    
    Write-Host "Checking CPU usage (may take a moment for metrics to update)..."
    kubectl top pods -n eshop
    
    Write-Host "Waiting for experiment to complete (5 minutes)..."
    Start-Sleep 310
    
    kubectl delete stresschaos eshop-cpu-stress -n eshop
    Write-Host "✅ CPU stress experiment completed" -ForegroundColor Green
}

# Function to run network delay experiment
function Start-NetworkDelayExperiment {
    Write-Host "🔥 Running Network Delay Experiment..." -ForegroundColor Red
    
    kubectl apply -f k8s/network-delay-chaos.yaml
    Start-Sleep 5
    
    Write-Host "Monitoring network delay experiment..."
    kubectl get networkchaos -n eshop
    kubectl describe networkchaos eshop-network-delay -n eshop
    
    Write-Host "Waiting for experiment to complete (3 minutes)..."
    Start-Sleep 190
    
    kubectl delete networkchaos eshop-network-delay -n eshop
    Write-Host "✅ Network delay experiment completed" -ForegroundColor Green
}

# Check initial application health
if (-not (Test-ApplicationHealth)) {
    Write-Host "❌ Application is not healthy. Please check your deployment before running chaos tests." -ForegroundColor Red
    exit 1
}

# Run experiments based on type
switch ($ExperimentType) {
    "pod-failure" {
        Start-PodFailureExperiment
    }
    "cpu-stress" {
        Start-CpuStressExperiment
    }
    "network-delay" {
        Start-NetworkDelayExperiment
    }
    "all" {
        Write-Host "🔥 Running all chaos experiments..." -ForegroundColor Red
        Start-PodFailureExperiment
        Start-Sleep 30
        Start-CpuStressExperiment
        Start-Sleep 30
        Start-NetworkDelayExperiment
    }
}

# Final health check
Write-Host "🔍 Final application health check..." -ForegroundColor Cyan
Start-Sleep 30
Test-ApplicationHealth

Write-Host "🎉 Chaos engineering tests completed!" -ForegroundColor Green
Write-Host "Check the Chaos Mesh dashboard at http://localhost:2333 for detailed experiment results" -ForegroundColor Yellow
