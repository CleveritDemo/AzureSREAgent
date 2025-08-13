# Fix Azure Chaos Studio Permissions
# This script assigns the necessary permissions to Chaos Studio experiment managed identities

param(
    [Parameter(Mandatory=$false)]
    [string]$SubscriptionId = "d7d7369b-a14f-43bc-a564-b4a077d170a9",
    
    [Parameter(Mandatory=$false)]
    [string]$ResourceGroup = "eShopCleverRG",
    
    [Parameter(Mandatory=$false)]
    [string]$ClusterName = "eshopcleveraks"
)

Write-Host "🔧 Fixing Azure Chaos Studio Permissions..." -ForegroundColor Green
Write-Host "📋 Subscription: $SubscriptionId" -ForegroundColor Yellow
Write-Host "📋 Resource Group: $ResourceGroup" -ForegroundColor Yellow
Write-Host "📋 AKS Cluster: $ClusterName" -ForegroundColor Yellow

# Set the subscription
az account set --subscription $SubscriptionId

# Define the experiments and their principal IDs
$experiments = @{
    "eshoppodfailure" = "635492a3-62d5-47ac-bda2-f8b0d2cc9680"
    "eshopcpustress" = "52b51e01-7c92-4d8d-b22e-2889fa0b9171"
    "eshopmemorystress" = "4680b558-560e-496d-bb4a-1821de55e86f"
    "eshopnetworkdelay" = "f92f5520-2a9a-4921-9606-5d07ce8af059"
}

# Get AKS resource ID
$aksResourceId = "/subscriptions/$SubscriptionId/resourceGroups/$ResourceGroup/providers/Microsoft.ContainerService/managedClusters/$ClusterName"
Write-Host "📋 AKS Resource ID: $aksResourceId" -ForegroundColor Gray

# Required roles for Chaos Studio on AKS
$requiredRoles = @(
    "Azure Kubernetes Service Cluster User Role",  # For AKS access
    "Contributor"  # For Chaos operations on the AKS cluster
)

foreach ($experiment in $experiments.GetEnumerator()) {
    $experimentName = $experiment.Key
    $principalId = $experiment.Value
    
    Write-Host "`n🎯 Configuring permissions for: $experimentName" -ForegroundColor Cyan
    Write-Host "📋 Principal ID: $principalId" -ForegroundColor Gray
    
    foreach ($role in $requiredRoles) {
        Write-Host "🔐 Assigning role: $role" -ForegroundColor Yellow
        
        try {
            # Check if role assignment already exists
            $existing = az role assignment list --assignee $principalId --role $role --scope $aksResourceId --query "[0].id" -o tsv 2>$null
            
            if ($existing) {
                Write-Host "   ✅ Role assignment already exists" -ForegroundColor Green
            } else {
                # Create the role assignment
                $result = az role assignment create --assignee $principalId --role $role --scope $aksResourceId
                if ($LASTEXITCODE -eq 0) {
                    Write-Host "   ✅ Role assignment created successfully" -ForegroundColor Green
                } else {
                    Write-Host "   ❌ Failed to create role assignment" -ForegroundColor Red
                }
            }
        } catch {
            Write-Host "   ⚠️ Error checking/creating role assignment: $_" -ForegroundColor Yellow
        }
    }
    
    # Also assign permissions at the resource group level for additional operations
    Write-Host "🔐 Assigning Resource Group Contributor role" -ForegroundColor Yellow
    $rgScope = "/subscriptions/$SubscriptionId/resourceGroups/$ResourceGroup"
    
    try {
        $existing = az role assignment list --assignee $principalId --role "Contributor" --scope $rgScope --query "[0].id" -o tsv 2>$null
        
        if ($existing) {
            Write-Host "   ✅ Resource Group role assignment already exists" -ForegroundColor Green
        } else {
            $result = az role assignment create --assignee $principalId --role "Contributor" --scope $rgScope
            if ($LASTEXITCODE -eq 0) {
                Write-Host "   ✅ Resource Group role assignment created successfully" -ForegroundColor Green
            } else {
                Write-Host "   ❌ Failed to create Resource Group role assignment" -ForegroundColor Red
            }
        }
    } catch {
        Write-Host "   ⚠️ Error with Resource Group role assignment: $_" -ForegroundColor Yellow
    }
}

# Additional step: Enable Chaos Studio on the AKS cluster if not already enabled
Write-Host "`n🎯 Ensuring Chaos Studio target is properly configured..." -ForegroundColor Cyan

$targetUrl = "https://management.azure.com$aksResourceId/providers/Microsoft.Chaos/targets/Microsoft-AzureKubernetesServiceChaosMesh?api-version=2023-11-01"

try {
    $target = az rest --method get --url $targetUrl 2>$null
    if ($target) {
        Write-Host "✅ Chaos Studio target is properly configured" -ForegroundColor Green
    }
} catch {
    Write-Host "⚠️ Chaos Studio target might need reconfiguration" -ForegroundColor Yellow
}

# Wait for role assignments to propagate
Write-Host "`n⏳ Waiting for role assignments to propagate (30 seconds)..." -ForegroundColor Yellow
Start-Sleep 30

Write-Host "`n🎉 Permission configuration completed!" -ForegroundColor Green
Write-Host "🚀 You can now try running your Chaos Studio experiments again." -ForegroundColor Cyan
Write-Host "📝 If you still encounter issues, wait a few more minutes for permissions to fully propagate." -ForegroundColor Gray

Write-Host "`n📊 Summary of configured permissions:" -ForegroundColor Yellow
Write-Host "   • Azure Kubernetes Service Cluster User Role on AKS" -ForegroundColor Gray
Write-Host "   • Contributor role on AKS cluster" -ForegroundColor Gray  
Write-Host "   • Contributor role on Resource Group" -ForegroundColor Gray
Write-Host "   • Applied to all 4 chaos experiments" -ForegroundColor Gray
