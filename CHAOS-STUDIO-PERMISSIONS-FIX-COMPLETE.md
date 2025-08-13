# 🔧 Azure Chaos Studio Permissions Fix - Complete Guide

## 🚨 Problem Description
The Azure Chaos Studio experiments are failing with "AccessDenied" errors because their system-assigned managed identities lack the necessary permissions to interact with the AKS cluster.

**Error Message:**
```
The target resource(s) could not be resolved. Please ensure that target resource(s) exist and Chaos Studio has appropriate permissions. Error Code: AccessDenied
```

## 🎯 Root Cause
Each Chaos Studio experiment has a system-assigned managed identity that needs:
1. **Azure Kubernetes Service Cluster User Role** on the AKS cluster
2. **Contributor** role on the AKS cluster

## 📋 Affected Experiments & Principal IDs

| Experiment Name | Managed Identity Principal ID |
|----------------|------------------------------|
| eshoppodfailure | `635492a3-62d5-47ac-bda2-f8b0d2cc9680` |
| eshopcpustress | `52b51e01-7c92-4d8d-b22e-2889fa0b9171` |
| eshopmemorystress | `4680b558-560e-496d-bb4a-1821de55e86f` |
| eshopnetworkdelay | `f92f5520-2a9a-4921-9606-5d07ce8af059` |

## ⚠️ Required Permissions to Fix
To run the fix commands, you need one of these roles on the AKS cluster:
- **Owner** role
- **User Access Administrator** role
- **Contributor** + **Role Based Access Control Administrator** roles

## 🛠️ Solution Options

### Option 1: Using Service Principal (Recommended)
Use the existing service principal `2e5ce55e-70e6-44b8-94b5-14f174babccd` which has **Contributor** permissions:

```powershell
# Authenticate as the service principal (if you have credentials)
az login --service-principal -u "2e5ce55e-70e6-44b8-94b5-14f174babccd" -p "CLIENT_SECRET" --tenant "1c8ef991-ec57-4212-b273-fb4e9ccd060d"
```

### Option 2: Admin Account (Alternative)
Have an administrator with proper permissions run the commands below.

## 🔐 Fix Commands

### Setup
```bash
# Set subscription
az account set --subscription "d7d7369b-a14f-43bc-a564-b4a077d170a9"

# Define AKS scope
AKS_SCOPE="/subscriptions/d7d7369b-a14f-43bc-a564-b4a077d170a9/resourceGroups/eShopCleverRG/providers/Microsoft.ContainerService/managedClusters/eshopcleveraks"
```

### Role Assignments

#### eshoppodfailure experiment (Principal ID: 635492a3-62d5-47ac-bda2-f8b0d2cc9680)
```bash
az role assignment create \
  --assignee-object-id "635492a3-62d5-47ac-bda2-f8b0d2cc9680" \
  --role "Azure Kubernetes Service Cluster User Role" \
  --scope "$AKS_SCOPE" \
  --assignee-principal-type "ServicePrincipal"

az role assignment create \
  --assignee-object-id "635492a3-62d5-47ac-bda2-f8b0d2cc9680" \
  --role "Contributor" \
  --scope "$AKS_SCOPE" \
  --assignee-principal-type "ServicePrincipal"
```

#### eshopcpustress experiment (Principal ID: 52b51e01-7c92-4d8d-b22e-2889fa0b9171)
```bash
az role assignment create \
  --assignee-object-id "52b51e01-7c92-4d8d-b22e-2889fa0b9171" \
  --role "Azure Kubernetes Service Cluster User Role" \
  --scope "$AKS_SCOPE" \
  --assignee-principal-type "ServicePrincipal"

az role assignment create \
  --assignee-object-id "52b51e01-7c92-4d8d-b22e-2889fa0b9171" \
  --role "Contributor" \
  --scope "$AKS_SCOPE" \
  --assignee-principal-type "ServicePrincipal"
```

#### eshopmemorystress experiment (Principal ID: 4680b558-560e-496d-bb4a-1821de55e86f)
```bash
az role assignment create \
  --assignee-object-id "4680b558-560e-496d-bb4a-1821de55e86f" \
  --role "Azure Kubernetes Service Cluster User Role" \
  --scope "$AKS_SCOPE" \
  --assignee-principal-type "ServicePrincipal"

az role assignment create \
  --assignee-object-id "4680b558-560e-496d-bb4a-1821de55e86f" \
  --role "Contributor" \
  --scope "$AKS_SCOPE" \
  --assignee-principal-type "ServicePrincipal"
```

#### eshopnetworkdelay experiment (Principal ID: f92f5520-2a9a-4921-9606-5d07ce8af059)
```bash
az role assignment create \
  --assignee-object-id "f92f5520-2a9a-4921-9606-5d07ce8af059" \
  --role "Azure Kubernetes Service Cluster User Role" \
  --scope "$AKS_SCOPE" \
  --assignee-principal-type "ServicePrincipal"

az role assignment create \
  --assignee-object-id "f92f5520-2a9a-4921-9606-5d07ce8af059" \
  --role "Contributor" \
  --scope "$AKS_SCOPE" \
  --assignee-principal-type "ServicePrincipal"
```

## 📜 PowerShell Script Version

```powershell
# Set subscription
az account set --subscription "d7d7369b-a14f-43bc-a564-b4a077d170a9"

# Define variables
$aksScope = "/subscriptions/d7d7369b-a14f-43bc-a564-b4a077d170a9/resourceGroups/eShopCleverRG/providers/Microsoft.ContainerService/managedClusters/eshopcleveraks"
$experiments = @{
    "eshoppodfailure" = "635492a3-62d5-47ac-bda2-f8b0d2cc9680"
    "eshopcpustress" = "52b51e01-7c92-4d8d-b22e-2889fa0b9171"
    "eshopmemorystress" = "4680b558-560e-496d-bb4a-1821de55e86f"
    "eshopnetworkdelay" = "f92f5520-2a9a-4921-9606-5d07ce8af059"
}
$roles = @("Azure Kubernetes Service Cluster User Role", "Contributor")

# Apply role assignments
foreach ($experiment in $experiments.GetEnumerator()) {
    $principalId = $experiment.Value
    $name = $experiment.Key
    Write-Host "Processing $name ($principalId)..."
    
    foreach ($role in $roles) {
        Write-Host "  Assigning role: $role"
        az role assignment create --assignee-object-id $principalId --role $role --scope $aksScope --assignee-principal-type "ServicePrincipal"
    }
}
```

## ✅ Verification Commands

### Check role assignments for a specific experiment:
```bash
az role assignment list \
  --assignee "635492a3-62d5-47ac-bda2-f8b0d2cc9680" \
  --scope "/subscriptions/d7d7369b-a14f-43bc-a564-b4a077d170a9/resourceGroups/eShopCleverRG/providers/Microsoft.ContainerService/managedClusters/eshopcleveraks" \
  --output table
```

### Check all chaos experiment role assignments:
```bash
# Check all experiments
for principal in "635492a3-62d5-47ac-bda2-f8b0d2cc9680" "52b51e01-7c92-4d8d-b22e-2889fa0b9171" "4680b558-560e-496d-bb4a-1821de55e86f" "f92f5520-2a9a-4921-9606-5d07ce8af059"; do
  echo "Checking principal: $principal"
  az role assignment list --assignee "$principal" --scope "$AKS_SCOPE" --output table
  echo "---"
done
```

## ⏳ Post-Fix Steps

1. **Wait for propagation**: Allow 5-10 minutes for permissions to propagate through Azure
2. **Test experiments**: Go to Azure Portal → Chaos Studio → Experiments
3. **Run a test**: Select one experiment and click "Start experiment"
4. **Verify success**: The experiment should now run without "AccessDenied" errors

## 🌐 Quick Links

- **Chaos Studio Portal**: https://portal.azure.com/#view/Microsoft_Azure_Chaos/ChaosStudioMenuBlade/~/experiments
- **AKS Cluster**: https://portal.azure.com/#@1c8ef991-ec57-4212-b273-fb4e9ccd060d/resource/subscriptions/d7d7369b-a14f-43bc-a564-b4a077d170a9/resourceGroups/eShopCleverRG/providers/Microsoft.ContainerService/managedClusters/eshopcleveraks/overview

## 🏗️ Alternative: Terraform Fix

If you prefer to use Terraform (requires proper permissions):

```hcl
# Add to your Terraform configuration
resource "azurerm_role_assignment" "chaos_experiments_aks_user" {
  for_each = {
    "eshoppodfailure" = "635492a3-62d5-47ac-bda2-f8b0d2cc9680"
    "eshopcpustress" = "52b51e01-7c92-4d8d-b22e-2889fa0b9171"
    "eshopmemorystress" = "4680b558-560e-496d-bb4a-1821de55e86f"
    "eshopnetworkdelay" = "f92f5520-2a9a-4921-9606-5d07ce8af059"
  }

  scope              = "/subscriptions/d7d7369b-a14f-43bc-a564-b4a077d170a9/resourceGroups/eShopCleverRG/providers/Microsoft.ContainerService/managedClusters/eshopcleveraks"
  role_definition_name = "Azure Kubernetes Service Cluster User Role"
  principal_id       = each.value
}

resource "azurerm_role_assignment" "chaos_experiments_contributor" {
  for_each = {
    "eshoppodfailure" = "635492a3-62d5-47ac-bda2-f8b0d2cc9680"
    "eshopcpustress" = "52b51e01-7c92-4d8d-b22e-2889fa0b9171"
    "eshopmemorystress" = "4680b558-560e-496d-bb4a-1821de55e86f"
    "eshopnetworkdelay" = "f92f5520-2a9a-4921-9606-5d07ce8af059"
  }

  scope              = "/subscriptions/d7d7369b-a14f-43bc-a564-b4a077d170a9/resourceGroups/eShopCleverRG/providers/Microsoft.ContainerService/managedClusters/eshopcleveraks"
  role_definition_name = "Contributor"
  principal_id       = each.value
}
```

## 📝 Summary

This fix addresses the root cause of the Chaos Studio experiment failures by granting the necessary permissions to each experiment's managed identity. After applying these role assignments and waiting for propagation, your chaos engineering experiments should run successfully without "AccessDenied" errors.

**Key Points:**
- 4 experiments need permissions
- 2 roles per experiment (8 total role assignments)
- Requires elevated permissions to execute
- 5-10 minute propagation time
- Service principal `2e5ce55e-70e6-44b8-94b5-14f174babccd` has the necessary permissions if credentials are available
