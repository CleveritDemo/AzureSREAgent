# 🔧 Azure Chaos Studio Permissions Fix Guide

## Problem
The Azure Chaos Studio experiments are failing with the error:
```
"The target resource(s) could not be resolved. Please verify that your target resource ID(s) are properly formatted, the targets exist, and your managed identity has sufficient permissions on all target resources. Error Code: AccessDenied."
```

## Root Cause
The managed identities created for each Chaos Studio experiment don't have the necessary permissions to access the AKS cluster.

## Solution
The following role assignments need to be created for each chaos experiment's managed identity.

## Required Role Assignments

### 1. Pod Failure Experiment (eshoppodfailure)
**Principal ID**: `635492a3-62d5-47ac-bda2-f8b0d2cc9680`

```bash
# Azure Kubernetes Service Cluster User Role
az role assignment create \
  --assignee "635492a3-62d5-47ac-bda2-f8b0d2cc9680" \
  --role "Azure Kubernetes Service Cluster User Role" \
  --scope "/subscriptions/d7d7369b-a14f-43bc-a564-b4a077d170a9/resourceGroups/eShopCleverRG/providers/Microsoft.ContainerService/managedClusters/eshopcleveraks"

# Contributor Role
az role assignment create \
  --assignee "635492a3-62d5-47ac-bda2-f8b0d2cc9680" \
  --role "Contributor" \
  --scope "/subscriptions/d7d7369b-a14f-43bc-a564-b4a077d170a9/resourceGroups/eShopCleverRG/providers/Microsoft.ContainerService/managedClusters/eshopcleveraks"
```

### 2. CPU Stress Experiment (eshopcpustress)
**Principal ID**: `52b51e01-7c92-4d8d-b22e-2889fa0b9171`

```bash
# Azure Kubernetes Service Cluster User Role
az role assignment create \
  --assignee "52b51e01-7c92-4d8d-b22e-2889fa0b9171" \
  --role "Azure Kubernetes Service Cluster User Role" \
  --scope "/subscriptions/d7d7369b-a14f-43bc-a564-b4a077d170a9/resourceGroups/eShopCleverRG/providers/Microsoft.ContainerService/managedClusters/eshopcleveraks"

# Contributor Role
az role assignment create \
  --assignee "52b51e01-7c92-4d8d-b22e-2889fa0b9171" \
  --role "Contributor" \
  --scope "/subscriptions/d7d7369b-a14f-43bc-a564-b4a077d170a9/resourceGroups/eShopCleverRG/providers/Microsoft.ContainerService/managedClusters/eshopcleveraks"
```

### 3. Memory Stress Experiment (eshopmemorystress)
**Principal ID**: `4680b558-560e-496d-bb4a-1821de55e86f`

```bash
# Azure Kubernetes Service Cluster User Role
az role assignment create \
  --assignee "4680b558-560e-496d-bb4a-1821de55e86f" \
  --role "Azure Kubernetes Service Cluster User Role" \
  --scope "/subscriptions/d7d7369b-a14f-43bc-a564-b4a077d170a9/resourceGroups/eShopCleverRG/providers/Microsoft.ContainerService/managedClusters/eshopcleveraks"

# Contributor Role
az role assignment create \
  --assignee "4680b558-560e-496d-bb4a-1821de55e86f" \
  --role "Contributor" \
  --scope "/subscriptions/d7d7369b-a14f-43bc-a564-b4a077d170a9/resourceGroups/eShopCleverRG/providers/Microsoft.ContainerService/managedClusters/eshopcleveraks"
```

### 4. Network Delay Experiment (eshopnetworkdelay)
**Principal ID**: `f92f5520-2a9a-4921-9606-5d07ce8af059`

```bash
# Azure Kubernetes Service Cluster User Role
az role assignment create \
  --assignee "f92f5520-2a9a-4921-9606-5d07ce8af059" \
  --role "Azure Kubernetes Service Cluster User Role" \
  --scope "/subscriptions/d7d7369b-a14f-43bc-a564-b4a077d170a9/resourceGroups/eShopCleverRG/providers/Microsoft.ContainerService/managedClusters/eshopcleveraks"

# Contributor Role
az role assignment create \
  --assignee "f92f5520-2a9a-4921-9606-5d07ce8af059" \
  --role "Contributor" \
  --scope "/subscriptions/d7d7369b-a14f-43bc-a564-b4a077d170a9/resourceGroups/eShopCleverRG/providers/Microsoft.ContainerService/managedClusters/eshopcleveraks"
```

## All-in-One Script

```bash
#!/bin/bash

# Set the subscription
az account set --subscription "d7d7369b-a14f-43bc-a564-b4a077d170a9"

# AKS cluster scope
AKS_SCOPE="/subscriptions/d7d7369b-a14f-43bc-a564-b4a077d170a9/resourceGroups/eShopCleverRG/providers/Microsoft.ContainerService/managedClusters/eshopcleveraks"

# Experiments and their principal IDs
declare -A EXPERIMENTS=(
    ["eshoppodfailure"]="635492a3-62d5-47ac-bda2-f8b0d2cc9680"
    ["eshopcpustress"]="52b51e01-7c92-4d8d-b22e-2889fa0b9171"
    ["eshopmemorystress"]="4680b558-560e-496d-bb4a-1821de55e86f"
    ["eshopnetworkdelay"]="f92f5520-2a9a-4921-9606-5d07ce8af059"
)

# Required roles
ROLES=("Azure Kubernetes Service Cluster User Role" "Contributor")

echo "🔧 Fixing Azure Chaos Studio Permissions..."

for experiment in "${!EXPERIMENTS[@]}"; do
    principal_id="${EXPERIMENTS[$experiment]}"
    echo "🎯 Configuring permissions for: $experiment"
    echo "📋 Principal ID: $principal_id"
    
    for role in "${ROLES[@]}"; do
        echo "🔐 Assigning role: $role"
        
        az role assignment create \
            --assignee "$principal_id" \
            --role "$role" \
            --scope "$AKS_SCOPE" \
            --assignee-object-id "$principal_id" \
            --assignee-principal-type "ServicePrincipal"
        
        if [ $? -eq 0 ]; then
            echo "   ✅ Role assignment successful"
        else
            echo "   ❌ Role assignment failed"
        fi
    done
    echo ""
done

echo "🎉 Permission configuration completed!"
echo "⏳ Please wait 5-10 minutes for permissions to propagate before testing experiments."
```

## PowerShell Alternative

```powershell
# Set the subscription
az account set --subscription "d7d7369b-a14f-43bc-a564-b4a077d170a9"

# AKS cluster scope
$AKS_SCOPE = "/subscriptions/d7d7369b-a14f-43bc-a564-b4a077d170a9/resourceGroups/eShopCleverRG/providers/Microsoft.ContainerService/managedClusters/eshopcleveraks"

# Experiments and their principal IDs
$EXPERIMENTS = @{
    "eshoppodfailure" = "635492a3-62d5-47ac-bda2-f8b0d2cc9680"
    "eshopcpustress" = "52b51e01-7c92-4d8d-b22e-2889fa0b9171"
    "eshopmemorystress" = "4680b558-560e-496d-bb4a-1821de55e86f"
    "eshopnetworkdelay" = "f92f5520-2a9a-4921-9606-5d07ce8af059"
}

# Required roles
$ROLES = @("Azure Kubernetes Service Cluster User Role", "Contributor")

Write-Host "🔧 Fixing Azure Chaos Studio Permissions..." -ForegroundColor Green

foreach ($experiment in $EXPERIMENTS.GetEnumerator()) {
    $experimentName = $experiment.Key
    $principalId = $experiment.Value
    
    Write-Host "🎯 Configuring permissions for: $experimentName" -ForegroundColor Cyan
    Write-Host "📋 Principal ID: $principalId" -ForegroundColor Gray
    
    foreach ($role in $ROLES) {
        Write-Host "🔐 Assigning role: $role" -ForegroundColor Yellow
        
        $result = az role assignment create --assignee $principalId --role $role --scope $AKS_SCOPE --assignee-object-id $principalId --assignee-principal-type "ServicePrincipal"
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "   ✅ Role assignment successful" -ForegroundColor Green
        } else {
            Write-Host "   ❌ Role assignment failed" -ForegroundColor Red
        }
    }
    Write-Host ""
}

Write-Host "🎉 Permission configuration completed!" -ForegroundColor Green
Write-Host "⏳ Please wait 5-10 minutes for permissions to propagate before testing experiments." -ForegroundColor Yellow
```

## Who Can Run These Commands?

These commands need to be run by a user or service principal that has:
- **User Access Administrator** role on the AKS cluster, OR
- **Owner** role on the AKS cluster, OR  
- **Contributor** role + **Role Based Access Control Administrator** role

## Alternative: Azure Portal Method

1. **Navigate to Azure Portal** → **Azure Kubernetes Service** → **eshopcleveraks**
2. **Go to "Access control (IAM)"**
3. **Click "Add" → "Add role assignment"**
4. **For each Principal ID listed above:**
   - Select **"Azure Kubernetes Service Cluster User Role"**
   - In "Members", select **"Managed identity"**
   - Find the chaos experiment by name
   - Click **"Select"** and **"Review + assign"**
   - Repeat for **"Contributor"** role

## Testing After Fix

Once the permissions are applied:

1. **Wait 5-10 minutes** for role assignments to propagate
2. **Go to Azure Portal** → **Chaos Studio** → **Experiments**
3. **Select any experiment** (e.g., eshoppodfailure)
4. **Click "Start"** to run the experiment
5. **Monitor the execution** - it should now work without the AccessDenied error

## Verification Commands

```bash
# Verify role assignments for pod failure experiment
az role assignment list --assignee "635492a3-62d5-47ac-bda2-f8b0d2cc9680" --scope "/subscriptions/d7d7369b-a14f-43bc-a564-b4a077d170a9/resourceGroups/eShopCleverRG/providers/Microsoft.ContainerService/managedClusters/eshopcleveraks" --output table

# Check all experiments
for principal_id in "635492a3-62d5-47ac-bda2-f8b0d2cc9680" "52b51e01-7c92-4d8d-b22e-2889fa0b9171" "4680b558-560e-496d-bb4a-1821de55e86f" "f92f5520-2a9a-4921-9606-5d07ce8af059"; do
    echo "Checking $principal_id:"
    az role assignment list --assignee "$principal_id" --output table
    echo ""
done
```

## Summary

Once these role assignments are created, all 4 Azure Chaos Studio experiments should be able to access the AKS cluster and run successfully. The experiments will then be able to execute chaos engineering tests on your eShopOnWeb application running in the `eshop` namespace.
