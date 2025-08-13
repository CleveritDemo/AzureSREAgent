# 🔐 GitHub Repository Secrets Setup Guide

## 📋 Required Azure Credentials

Based on your current Azure environment, you need to configure the following secrets in your GitHub repository:

### 🎯 Azure Authentication Values

| Secret Name | Value | Description |
|-------------|-------|-------------|
| `AZURE_SUBSCRIPTION_ID` | `d7d7369b-a14f-43bc-a564-b4a077d170a9` | Your Azure Subscription ID |
| `AZURE_TENANT_ID` | `1c8ef991-ec57-4212-b273-fb4e9ccd060d` | Cleverit Group Tenant ID |
| `AZURE_CLIENT_ID` | `[NEED TO CREATE SERVICE PRINCIPAL]` | Service Principal Application ID |

---

## 🚀 Step-by-Step Setup

### 1. Create Azure Service Principal

First, you need to create a service principal for GitHub Actions authentication:

```bash
# Create service principal with Contributor role
az ad sp create-for-rbac \
  --name "github-actions-chaos-experiments" \
  --role "Contributor" \
  --scopes "/subscriptions/d7d7369b-a14f-43bc-a564-b4a077d170a9/resourceGroups/eShopCleverRG" \
  --sdk-auth
```

**Save the output!** You'll need the `clientId` value for `AZURE_CLIENT_ID`.

### 2. Add Chaos Studio Permissions

The service principal needs additional permissions for Chaos Studio:

```bash
# Get the service principal object ID (replace CLIENT_ID with actual value)
SP_OBJECT_ID=$(az ad sp show --id <CLIENT_ID> --query id -o tsv)

# Add Chaos Studio Experiment Admin role
az role assignment create \
  --assignee $SP_OBJECT_ID \
  --role "Chaos Studio Experiment Admin" \
  --scope "/subscriptions/d7d7369b-a14f-43bc-a564-b4a077d170a9/resourceGroups/eShopCleverRG"
```

### 3. Configure GitHub Repository Secrets

Go to your GitHub repository: `https://github.com/CleveritDemo/AzureSREAgent`

1. **Navigate to**: Settings → Secrets and variables → Actions
2. **Click**: "New repository secret"
3. **Add each secret**:

#### Secret 1: AZURE_SUBSCRIPTION_ID
- **Name**: `AZURE_SUBSCRIPTION_ID`
- **Value**: `d7d7369b-a14f-43bc-a564-b4a077d170a9`

#### Secret 2: AZURE_TENANT_ID
- **Name**: `AZURE_TENANT_ID`
- **Value**: `1c8ef991-ec57-4212-b273-fb4e9ccd060d`

#### Secret 3: AZURE_CLIENT_ID
- **Name**: `AZURE_CLIENT_ID`
- **Value**: `[The clientId from service principal creation]`

---

## 🔧 Alternative: Using Your Current User

If you prefer to use your current authenticated user instead of a service principal:

### Option A: Get Current User's Application ID

```bash
# Get your current user's details
az account show --query "user" -o table

# If you have a user-assigned managed identity or application registration
az ad signed-in-user show --query "id" -o tsv
```

### Option B: Create App Registration

```bash
# Create an app registration for GitHub Actions
az ad app create \
  --display-name "GitHub-Actions-Chaos-Experiments" \
  --sign-in-audience "AzureADMyOrg"

# Get the application ID
az ad app list \
  --display-name "GitHub-Actions-Chaos-Experiments" \
  --query "[0].appId" -o tsv
```

---

## ✅ Verification

After setting up the secrets, verify they work by:

1. **Go to**: GitHub Actions tab in your repository
2. **Run**: "Manual Chaos Experiment Trigger" workflow
3. **Select**: Any experiment (e.g., "Pod Failure")
4. **Check**: The workflow should authenticate successfully

### Expected Output
```
✅ Azure CLI setup complete
AKS Cluster Status: Succeeded
Current pods in eshop namespace: [pod list]
Chaos Studio Target: Microsoft-AzureKubernetesServiceChaosMesh
```

---

## 🔐 Security Notes

### Current Environment Details
- **Account**: `traidr.sf2155@cleveritgroup.com`
- **Tenant**: `Cleverit Group` (cleveritgroup.com)
- **Subscription**: `Patrocinio de Microsoft Azure (cloud)`

### Best Practices
- ✅ Use service principal instead of personal credentials
- ✅ Grant minimum required permissions (Contributor + Chaos Studio Experiment Admin)
- ✅ Scope permissions to specific resource group only
- ✅ Regularly rotate service principal credentials
- ✅ Monitor service principal usage in Azure Activity Log

---

## 🚨 Troubleshooting

### Common Issues

1. **Authentication Failed**
   - Verify all three secrets are correctly set
   - Check service principal has required permissions
   - Ensure subscription ID matches your environment

2. **Chaos Experiment Access Denied**
   - Add "Chaos Studio Experiment Admin" role
   - Verify target AKS cluster is enabled for Chaos Studio

3. **Resource Group Not Found**
   - Confirm resource group name: `eShopCleverRG`
   - Verify subscription context is correct

### Debug Commands

```bash
# Test authentication locally
az login --service-principal \
  --username <CLIENT_ID> \
  --password <CLIENT_SECRET> \
  --tenant 1033d128-85ad-47b4-8c85-0a28b6ce0297

# Test Chaos Studio access
az rest --method GET \
  --url "https://management.azure.com/subscriptions/5f62fee3-b00a-44d2-86e5-5cf130b28b5d/resourceGroups/eShopCleverRG/providers/Microsoft.Chaos/experiments?api-version=2023-11-01"
```

---

## 🎯 Next Steps

1. ✅ **Update GitHub Workflow** - Already completed!
2. 🔄 **Create Service Principal** - Run the commands above
3. 🔄 **Add GitHub Secrets** - Configure in repository settings
4. 🔄 **Test Workflow** - Run a chaos experiment
5. 🔄 **Monitor Results** - Check Azure Portal for experiment status

Ready to chaos test! 🧪💥
