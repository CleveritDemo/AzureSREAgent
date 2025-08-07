# 🔐 Azure Chaos Studio Permission Fix Guide

## 🚨 **Issue Identified**
Your account `traidr.sf2155@cleveritgroup.com` has **Contributor** role but lacks permission to create role assignments required for Azure Chaos Studio experiments.

**Error**: `Microsoft.Authorization/roleAssignments/write` permission denied

## 📋 **Current Permissions**
```
User: traidr.sf2155@cleveritgroup.com
Object ID: 2e225e1b-e289-41d7-93bc-043d8c851629
Current Role: Contributor
Subscription: 5f62fee3-b00a-44d2-86e5-5cf130b28b5d
```

## 🎯 **Solutions (Choose One)**

### **Solution 1: Temporary User Access Administrator (Recommended)**
The tenant owner should grant you temporary **User Access Administrator** role:

#### For Tenant Owner to Execute:
```powershell
# Grant User Access Administrator role for Chaos Studio setup
az role assignment create \
  --assignee "2e225e1b-e289-41d7-93bc-043d8c851629" \
  --role "User Access Administrator" \
  --scope "/subscriptions/5f62fee3-b00a-44d2-86e5-5cf130b28b5d"

# Verify the assignment
az role assignment list --assignee "2e225e1b-e289-41d7-93bc-043d8c851629" --output table
```

#### After Chaos Studio Setup (Remove Temporary Permissions):
```powershell
# Remove temporary User Access Administrator role
az role assignment delete \
  --assignee "2e225e1b-e289-41d7-93bc-043d8c851629" \
  --role "User Access Administrator" \
  --scope "/subscriptions/5f62fee3-b00a-44d2-86e5-5cf130b28b5d"
```

### **Solution 2: Custom Role with Limited Permissions**
Create a custom role with only the required permissions:

#### For Tenant Owner to Execute:
```powershell
# Create custom role definition
$customRole = @"
{
  "Name": "Chaos Studio Operator",
  "Description": "Can create and manage Chaos Studio experiments",
  "Actions": [
    "Microsoft.Chaos/*",
    "Microsoft.Authorization/roleAssignments/write",
    "Microsoft.Authorization/roleAssignments/read",
    "Microsoft.Authorization/roleAssignments/delete",
    "Microsoft.ContainerService/managedClusters/read",
    "Microsoft.Resources/subscriptions/resourceGroups/read"
  ],
  "NotActions": [],
  "DataActions": [],
  "NotDataActions": [],
  "AssignableScopes": [
    "/subscriptions/5f62fee3-b00a-44d2-86e5-5cf130b28b5d/resourceGroups/eShopCleverRG"
  ]
}
"@

# Save to file and create role
$customRole | Out-File -FilePath "chaos-studio-role.json" -Encoding UTF8
az role definition create --role-definition "chaos-studio-role.json"

# Assign custom role to user
az role assignment create \
  --assignee "2e225e1b-e289-41d7-93bc-043d8c851629" \
  --role "Chaos Studio Operator" \
  --scope "/subscriptions/5f62fee3-b00a-44d2-86e5-5cf130b28b5d/resourceGroups/eShopCleverRG"
```

### **Solution 3: Tenant Owner Creates Experiments**
The tenant owner creates the experiments and grants you execution permissions:

#### For Tenant Owner to Execute:
```powershell
# Enable Chaos Studio target (tenant owner runs this)
$aksResourceId = "/subscriptions/5f62fee3-b00a-44d2-86e5-5cf130b28b5d/resourceGroups/eShopCleverRG/providers/Microsoft.ContainerService/managedClusters/eshopcleveraks"

# Register provider
az provider register --namespace Microsoft.Chaos --wait

# Enable target
az rest --method PUT \
  --url "https://management.azure.com$aksResourceId/providers/Microsoft.Chaos/targets/Microsoft-AzureKubernetesServiceChaosMesh?api-version=2024-01-01" \
  --headers "Content-Type=application/json" \
  --body '{"properties":{}}'

# Enable capabilities
$capabilities = @("PodChaos-2.2", "StressChaos-2.2", "NetworkChaos-2.2", "IOChaos-2.2")
foreach ($capability in $capabilities) {
    $capUrl = "https://management.azure.com$aksResourceId/providers/Microsoft.Chaos/targets/Microsoft-AzureKubernetesServiceChaosMesh/capabilities/$capability" + "?api-version=2024-01-01"
    az rest --method PUT --url $capUrl --headers "Content-Type=application/json" --body '{"properties":{}}'
}
```

## 🛠️ **Alternative: Use ARM Template Deployment**
If role assignment issues persist, use this ARM template approach:

### Create Pre-configured Experiments (Tenant Owner):
```powershell
# Deploy experiment using ARM template (avoids portal role assignment issues)
az deployment group create \
  --resource-group "eShopCleverRG" \
  --template-file "chaos-experiment-arm-template.json" \
  --parameters @chaos-experiment-parameters.json
```

## 📝 **Step-by-Step Resolution**

### **For You (Current User):**
1. **Request Permissions**: Share this guide with your tenant owner
2. **Wait for Permission Grant**: Tenant owner implements Solution 1 or 2
3. **Verify Access**: Run permission check commands below
4. **Create Experiments**: Follow the portal steps again

### **Permission Verification Commands:**
```powershell
# Check your current roles
az role assignment list --assignee "2e225e1b-e289-41d7-93bc-043d8c851629" --output table

# Test if you can create role assignments
az role assignment list --scope "/subscriptions/5f62fee3-b00a-44d2-86e5-5cf130b28b5d/resourceGroups/eShopCleverRG" --output table

# Check Chaos provider status
az provider show --namespace "Microsoft.Chaos" --query "registrationState"
```

## 🔒 **Security Best Practices**

### **Recommended Approach**:
1. **Use Solution 1** (Temporary User Access Administrator)
2. **Complete Chaos Studio setup**
3. **Remove elevated permissions immediately**
4. **Keep only Contributor + Chaos Studio specific roles**

### **Permission Scope Limitation**:
- Grant permissions only to resource group scope when possible
- Use time-limited role assignments
- Document all permission changes
- Regular permission audits

## 🎯 **After Permission Fix**

### **Once Permissions Are Granted:**
```powershell
# Verify you can proceed
az role assignment list --assignee "2e225e1b-e289-41d7-93bc-043d8c851629" --query "[].roleDefinitionName"

# Check if you can create Chaos Studio experiments
az provider show --namespace "Microsoft.Chaos" --query "registrationState"
```

### **Then Follow Portal Steps:**
1. ✅ **Enable Targets**: AKS cluster as Chaos Studio target
2. ✅ **Create Experiments**: Pod failure, CPU stress, network delay
3. ✅ **Run Experiments**: Start from Azure Portal
4. ✅ **Monitor Results**: Use integrated monitoring

## 📞 **Communication Template for Tenant Owner**

### **Email/Message Template:**
```
Subject: Azure Chaos Studio Permission Request - Temporary User Access Administrator

Hi [Tenant Owner],

I need temporary permissions to set up Azure Chaos Studio experiments for our eShopOnWeb SRE testing.

Required Action:
- Grant temporary "User Access Administrator" role to: traidr.sf2155@cleveritgroup.com
- Scope: Subscription 5f62fee3-b00a-44d2-86e5-5cf130b28b5d (or just eShopCleverRG resource group)
- Duration: 30 minutes (only for initial setup)

Commands to run:
az role assignment create --assignee "2e225e1b-e289-41d7-93bc-043d8c851629" --role "User Access Administrator" --scope "/subscriptions/5f62fee3-b00a-44d2-86e5-5cf130b28b5d"

After I complete the setup, please remove the temporary permissions:
az role assignment delete --assignee "2e225e1b-e289-41d7-93bc-043d8c851629" --role "User Access Administrator" --scope "/subscriptions/5f62fee3-b00a-44d2-86e5-5cf130b28b5d"

Purpose: Enable Azure Chaos Studio for resilience testing of our AKS applications
Risk: Low - temporary permission for specific setup task

Let me know when this is completed so I can proceed with the setup.

Thanks!
```

## 🚀 **Next Steps After Permission Grant**

1. **Confirm Permissions**: Run verification commands
2. **Return to Portal**: Continue with Chaos Studio setup
3. **Enable Targets**: Configure AKS cluster
4. **Create Experiments**: Use the templates from AZURE-CHAOS-STUDIO-SUMMARY.md
5. **Test Experiments**: Run your first chaos experiment
6. **Remove Elevated Permissions**: Ensure security compliance

---

**💡 Pro Tip**: Solution 1 (Temporary User Access Administrator) is the fastest and most secure approach. The setup only takes 5-10 minutes, then permissions can be immediately revoked.
