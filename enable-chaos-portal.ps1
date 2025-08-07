# Azure Portal Chaos Studio Integration Script
# This script enables Chaos Studio targets via Azure Portal
# REQUIRES: User Access Administrator role or proper permissions

param(
    [string]$SubscriptionId = "",
    [string]$ResourceGroupName = "eShopCleverRG",
    [string]$AksClusterName = "eshopcleveraks",
    [switch]$CheckPermissions
)

# Set error handling
$ErrorActionPreference = "Stop"

Write-Host "🔄 Azure Portal Chaos Studio Integration Script" -ForegroundColor Blue
Write-Host "================================================" -ForegroundColor Blue

# Function to check permissions
function Test-ChaosStudioPermissions {
    Write-Host "📋 Checking current user permissions..." -ForegroundColor Yellow
    
    try {
        # Get current user context
        $currentUser = az account show --query user.name -o tsv
        Write-Host "✅ Current user: $currentUser" -ForegroundColor Green
        
        # Check role assignments
        $roleAssignments = az role assignment list --assignee $currentUser --query "[?roleDefinitionName=='User Access Administrator' || roleDefinitionName=='Owner' || roleDefinitionName=='Contributor']" -o json | ConvertFrom-Json
        
        if ($roleAssignments) {
            Write-Host "✅ Found role assignments:" -ForegroundColor Green
            $roleAssignments | ForEach-Object {
                Write-Host "   - Role: $($_.roleDefinitionName)" -ForegroundColor Cyan
                Write-Host "   - Scope: $($_.scope)" -ForegroundColor Cyan
            }
        } else {
            Write-Host "❌ No relevant role assignments found" -ForegroundColor Red
        }
        
        # Test if we can list role assignments (requires appropriate permissions)
        try {
            $testResult = az role assignment list --resource-group $ResourceGroupName --query "length(@)" -o tsv 2>$null
            if ($testResult -ne $null) {
                Write-Host "✅ Can list role assignments in resource group" -ForegroundColor Green
            }
        } catch {
            Write-Host "❌ Cannot list role assignments - insufficient permissions" -ForegroundColor Red
        }
        
    } catch {
        Write-Host "❌ Error checking permissions: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Function to enable Chaos Studio target
function Enable-ChaosStudioTarget {
    param(
        [string]$TargetResourceId,
        [string]$TargetType
    )
    
    Write-Host "🎯 Enabling Chaos Studio target..." -ForegroundColor Yellow
    Write-Host "   Target: $TargetType" -ForegroundColor Cyan
    Write-Host "   Resource: $TargetResourceId" -ForegroundColor Cyan
    
    try {
        # Check if target already exists
        $existingTarget = az rest --method GET --url "$TargetResourceId/providers/Microsoft.Chaos/targets/$TargetType" --query "id" -o tsv 2>$null
        
        if ($existingTarget) {
            Write-Host "✅ Target already exists" -ForegroundColor Green
            return $true
        }
        
        # Create the target
        $body = @{
            properties = @{}
        } | ConvertTo-Json -Depth 3
        
        $result = az rest --method PUT --url "$TargetResourceId/providers/Microsoft.Chaos/targets/$TargetType" --body $body --headers "Content-Type=application/json" 2>&1
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✅ Successfully enabled Chaos Studio target" -ForegroundColor Green
            return $true
        } else {
            Write-Host "❌ Failed to enable target: $result" -ForegroundColor Red
            return $false
        }
        
    } catch {
        Write-Host "❌ Error enabling target: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

# Function to enable capabilities
function Enable-ChaosCapabilities {
    param(
        [string]$TargetResourceId,
        [string]$TargetType,
        [string[]]$Capabilities
    )
    
    Write-Host "🔧 Enabling Chaos capabilities..." -ForegroundColor Yellow
    
    foreach ($capability in $Capabilities) {
        Write-Host "   Enabling: $capability" -ForegroundColor Cyan
        
        try {
            $body = @{
                properties = @{}
            } | ConvertTo-Json -Depth 3
            
            $capabilityUrl = "$TargetResourceId/providers/Microsoft.Chaos/targets/$TargetType/capabilities/$capability"
            $result = az rest --method PUT --url $capabilityUrl --body $body --headers "Content-Type=application/json" 2>&1
            
            if ($LASTEXITCODE -eq 0) {
                Write-Host "   ✅ Enabled: $capability" -ForegroundColor Green
            } else {
                Write-Host "   ❌ Failed to enable $capability`: $result" -ForegroundColor Red
            }
            
        } catch {
            Write-Host "   ❌ Error enabling $capability`: $($_.Exception.Message)" -ForegroundColor Red
        }
    }
}

# Main execution
try {
    # Login check
    Write-Host "🔐 Checking Azure CLI authentication..." -ForegroundColor Yellow
    $account = az account show 2>$null
    if (-not $account) {
        Write-Host "❌ Not logged in to Azure CLI. Please run 'az login' first." -ForegroundColor Red
        exit 1
    }
    
    $accountInfo = $account | ConvertFrom-Json
    Write-Host "✅ Logged in as: $($accountInfo.user.name)" -ForegroundColor Green
    Write-Host "✅ Subscription: $($accountInfo.name) ($($accountInfo.id))" -ForegroundColor Green
    
    # Set subscription if provided
    if ($SubscriptionId) {
        Write-Host "🔄 Setting subscription to: $SubscriptionId" -ForegroundColor Yellow
        az account set --subscription $SubscriptionId
    }
    
    # Check permissions if requested
    if ($CheckPermissions) {
        Test-ChaosStudioPermissions
        return
    }
    
    # Get AKS cluster resource ID
    Write-Host "🔍 Getting AKS cluster information..." -ForegroundColor Yellow
    $aksCluster = az aks show --name $AksClusterName --resource-group $ResourceGroupName --query "{id:id,name:name,location:location}" -o json 2>$null
    
    if (-not $aksCluster) {
        Write-Host "❌ AKS cluster '$AksClusterName' not found in resource group '$ResourceGroupName'" -ForegroundColor Red
        exit 1
    }
    
    $clusterInfo = $aksCluster | ConvertFrom-Json
    Write-Host "✅ Found AKS cluster: $($clusterInfo.name)" -ForegroundColor Green
    Write-Host "   Resource ID: $($clusterInfo.id)" -ForegroundColor Cyan
    Write-Host "   Location: $($clusterInfo.location)" -ForegroundColor Cyan
    
    # Enable Chaos Studio provider (if not already done)
    Write-Host "🔄 Ensuring Chaos provider is registered..." -ForegroundColor Yellow
    az provider register --namespace Microsoft.Chaos --wait
    Write-Host "✅ Chaos provider registered" -ForegroundColor Green
    
    # Enable Chaos Studio target
    $targetType = "Microsoft-AzureKubernetesServiceChaosMesh"
    $targetEnabled = Enable-ChaosStudioTarget -TargetResourceId $clusterInfo.id -TargetType $targetType
    
    if ($targetEnabled) {
        # Enable capabilities
        $capabilities = @(
            "PodChaos-2.2",
            "StressChaos-2.2", 
            "NetworkChaos-2.2",
            "IOChaos-2.2"
        )
        
        Enable-ChaosCapabilities -TargetResourceId $clusterInfo.id -TargetType $targetType -Capabilities $capabilities
        
        Write-Host ""
        Write-Host "🎉 Chaos Studio target enabled successfully!" -ForegroundColor Green
        Write-Host ""
        Write-Host "📌 Next Steps:" -ForegroundColor Yellow
        Write-Host "1. Go to Azure Portal: https://portal.azure.com/#view/Microsoft_Azure_Chaos/ChaosStudio.MenuView/~/chaosExperiment" -ForegroundColor Cyan
        Write-Host "2. Click 'Create' to create a new experiment" -ForegroundColor Cyan
        Write-Host "3. Select your target: $($clusterInfo.name)" -ForegroundColor Cyan
        Write-Host "4. Choose capabilities like PodChaos, StressChaos, etc." -ForegroundColor Cyan
        Write-Host "5. Configure your experiment parameters" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "🔗 Portal Link: https://portal.azure.com/#@/resource$($clusterInfo.id)/chaos" -ForegroundColor Blue
        
    } else {
        Write-Host "❌ Failed to enable Chaos Studio target" -ForegroundColor Red
        Write-Host ""
        Write-Host "💡 Troubleshooting:" -ForegroundColor Yellow
        Write-Host "1. Ensure you have User Access Administrator or Owner role" -ForegroundColor Cyan
        Write-Host "2. Check if Chaos Studio provider is registered" -ForegroundColor Cyan
        Write-Host "3. Verify resource permissions" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "📖 For help, see: chaos-studio-permission-fix.md" -ForegroundColor Blue
    }
    
} catch {
    Write-Host "❌ Script execution failed: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "✅ Script completed!" -ForegroundColor Green
