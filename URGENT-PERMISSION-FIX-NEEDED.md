# 🚨 URGENT: Chaos Experiment Permission Issue

## Problem Identified
The new Azure Chaos Studio experiment `eshop-pod-failure` is still failing with the **AccessDenied** error, even after attempting to configure permissions.

## Root Cause
**I don't have sufficient privileges** to assign roles to managed identities. Based on our earlier conversation, this requires someone with:
- **User Access Administrator** role on the AKS cluster, OR
- **Owner** role on the AKS cluster, OR  
- **Contributor** role + **Role Based Access Control Administrator** role

## Required Action for Azure Tenant Owner

The Azure Tenant owner needs to execute these commands **immediately** for the new experiment:

### New Experiment Details
- **Experiment Name**: `eshop-pod-failure`
- **Principal ID**: `26ad1f83-e606-4d40-ad29-b576f5ef915b`

### Commands to Execute

```bash
# Set the subscription
az account set --subscription "d7d7369b-a14f-43bc-a564-b4a077d170a9"

# Azure Kubernetes Service Cluster User Role
az role assignment create \
  --assignee "26ad1f83-e606-4d40-ad29-b576f5ef915b" \
  --role "Azure Kubernetes Service Cluster User Role" \
  --scope "/subscriptions/d7d7369b-a14f-43bc-a564-b4a077d170a9/resourceGroups/eShopCleverRG/providers/Microsoft.ContainerService/managedClusters/eshopcleveraks"

# Contributor Role
az role assignment create \
  --assignee "26ad1f83-e606-4d40-ad29-b576f5ef915b" \
  --role "Contributor" \
  --scope "/subscriptions/d7d7369b-a14f-43bc-a564-b4a077d170a9/resourceGroups/eShopCleverRG/providers/Microsoft.ContainerService/managedClusters/eshopcleveraks"
```

### PowerShell Version

```powershell
# Set the subscription
az account set --subscription "d7d7369b-a14f-43bc-a564-b4a077d170a9"

$principalId = "26ad1f83-e606-4d40-ad29-b576f5ef915b"
$aksScope = "/subscriptions/d7d7369b-a14f-43bc-a564-b4a077d170a9/resourceGroups/eShopCleverRG/providers/Microsoft.ContainerService/managedClusters/eshopcleveraks"

Write-Host "🔧 Configuring permissions for eshop-pod-failure..." -ForegroundColor Green

# Azure Kubernetes Service Cluster User Role
Write-Host "🔐 Assigning Azure Kubernetes Service Cluster User Role..." -ForegroundColor Yellow
az role assignment create --assignee $principalId --role "Azure Kubernetes Service Cluster User Role" --scope $aksScope

# Contributor Role
Write-Host "🔐 Assigning Contributor Role..." -ForegroundColor Yellow
az role assignment create --assignee $principalId --role "Contributor" --scope $aksScope

Write-Host "✅ Permissions configured!" -ForegroundColor Green
```

## Verification Commands

After the Tenant owner runs the commands above, verify with:

```bash
# Check role assignments
az role assignment list --assignee "26ad1f83-e606-4d40-ad29-b576f5ef915b" --scope "/subscriptions/d7d7369b-a14f-43bc-a564-b4a077d170a9/resourceGroups/eShopCleverRG/providers/Microsoft.ContainerService/managedClusters/eshopcleveraks" --output table
```

Expected output should show both roles assigned.

## Testing After Fix

1. **Wait 5-10 minutes** for permissions to propagate
2. **Go to Azure Portal** → **Chaos Studio** → **Experiments** 
3. **Select `eshop-pod-failure`**
4. **Click "Start"** 
5. **Should execute without AccessDenied error**

## Current Status

- ✅ **Experiment Created**: `eshop-pod-failure` exists in Azure Portal
- ❌ **Permissions**: Not configured (insufficient privileges)
- 🔄 **Status**: Waiting for Tenant owner to assign roles

## Next Steps

1. **Contact Azure Tenant owner immediately**
2. **Provide them with the commands above**
3. **Wait for permissions to propagate**
4. **Test the experiment**
5. **Only then proceed with creating additional experiments**

---

**⚠️ CRITICAL**: Do not create more experiments until this permission issue is resolved, as they will all fail with the same error.
