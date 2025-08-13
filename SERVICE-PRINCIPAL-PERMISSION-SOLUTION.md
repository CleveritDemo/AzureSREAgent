# 🔐 Service Principal Creation - Permission Issues Solution

## 🚨 Current Issue

**Error**: `Insufficient privileges to complete the operation`
**Cause**: Your account `traidr.sf2155@cleveritgroup.com` lacks permissions to:
- Create service principals in Azure AD
- Query Azure AD Graph API
- Assign application roles

## 💡 Solutions (Choose One)

### Option 1: Request Admin to Create Service Principal (Recommended)

**Ask your Azure AD Administrator to run these commands:**

```bash
# 1. Create the service principal
az ad sp create-for-rbac \
  --name "github-actions-chaos-experiments" \
  --role "Contributor" \
  --scopes "/subscriptions/d7d7369b-a14f-43bc-a564-b4a077d170a9/resourceGroups/eShopCleverRG"

# 2. Add Chaos Studio permissions (replace <CLIENT_ID> with output from step 1)
az role assignment create \
  --assignee <CLIENT_ID> \
  --role "Chaos Studio Experiment Admin" \
  --scope "/subscriptions/d7d7369b-a14f-43bc-a564-b4a077d170a9/resourceGroups/eShopCleverRG"
```

**Note**: Using your correct subscription ID `d7d7369b-a14f-43bc-a564-b4a077d170a9` (CleverSubscription CSP).

---

### Option 2: Request Azure AD Permissions

**Ask your Azure AD Administrator to grant you:**

1. **Application Developer** role in Azure AD:
   ```bash
   # Admin runs this (replace <YOUR_USER_ID> with your object ID)
   az role assignment create \
     --assignee <YOUR_USER_ID> \
     --role "Application Developer" \
     --scope "/providers/Microsoft.Graph"
   ```

2. **Directory Readers** role (optional, for Graph API access):
   ```bash
   az role assignment create \
     --assignee <YOUR_USER_ID> \
     --role "Directory Readers" \
     --scope "/providers/Microsoft.Graph"
   ```

---

### Option 3: Use Existing Application (If Available)

**Check if there's already an app registration:**

```bash
# List existing app registrations (may work with limited permissions)
az ad app list --display-name "github" --query "[].{Name:displayName,AppId:appId}" -o table
```

If an existing app exists, use its Application ID as `AZURE_CLIENT_ID`.

---

### Option 4: Alternative Authentication - Federated Credentials (Modern Approach)

**Ask your admin to create an app registration with federated credentials instead of secrets:**

```bash
# 1. Create app registration
az ad app create --display-name "GitHub-Actions-Chaos-Experiments"

# 2. Get the app ID
APP_ID=$(az ad app list --display-name "GitHub-Actions-Chaos-Experiments" --query "[0].appId" -o tsv)

# 3. Create service principal
az ad sp create --id $APP_ID

# 4. Add role assignments
az role assignment create --assignee $APP_ID --role "Contributor" --scope "/subscriptions/d7d7369b-a14f-43bc-a564-b4a077d170a9/resourceGroups/eShopCleverRG"
az role assignment create --assignee $APP_ID --role "Chaos Studio Experiment Admin" --scope "/subscriptions/d7d7369b-a14f-43bc-a564-b4a077d170a9/resourceGroups/eShopCleverRG"

# 5. Add federated credential for GitHub Actions
az ad app federated-credential create \
  --id $APP_ID \
  --parameters '{
    "name": "github-actions-main",
    "issuer": "https://token.actions.githubusercontent.com",
    "subject": "repo:CleveritDemo/AzureSREAgent:ref:refs/heads/main",
    "audiences": ["api://AzureADTokenExchange"]
  }'
```

---

## 🎯 Quick Fix for Testing

**If you just want to test the chaos experiments immediately:**

### Manual Portal Testing
1. Go to Azure Portal → Chaos Studio
2. Manually run the chaos experiments we created
3. This doesn't require service principal creation

### Use Your Current Session
1. Run chaos experiments directly from your current Azure CLI session
2. Use the commands from our previous chaos testing

---

## 📋 Information for Your Administrator

**Send this to your Azure AD Admin:**

> Hi! I need to set up GitHub Actions for automated chaos experiments on our AKS cluster. Could you please create a service principal with the following details:
> 
> **Requirements:**
> - **Name**: `github-actions-chaos-experiments`
> - **Subscription**: `5f62fee3-b00a-44d2-86e5-5cf130b28b5d` (Patrocinio de Microsoft Azure)
> - **Resource Group**: `eShopCleverRG`
> - **Roles Needed**: 
>   - `Contributor` (for general Azure resource management)
>   - `Chaos Studio Experiment Admin` (for running chaos experiments)
> 
> **Commands to run:**
> ```bash
> # Create service principal
> az ad sp create-for-rbac \
>   --name "github-actions-chaos-experiments" \
>   --role "Contributor" \
>   --scopes "/subscriptions/5f62fee3-b00a-44d2-86e5-5cf130b28b5d/resourceGroups/eShopCleverRG"
> 
> # Add chaos studio permissions (replace <CLIENT_ID> with the appId from above)
> az role assignment create \
>   --assignee <CLIENT_ID> \
>   --role "Chaos Studio Experiment Admin" \
>   --scope "/subscriptions/5f62fee3-b00a-44d2-86e5-5cf130b28b5d/resourceGroups/eShopCleverRG"
> ```
> 
> Please provide me with the **appId** (Client ID) from the output so I can configure GitHub Actions.

---

## 🔍 Subscription ID Correction

**I noticed a discrepancy:**
- You used: `d7d7369b-a14f-43bc-a564-b4a077d170a9`
- Correct one: `5f62fee3-b00a-44d2-86e5-5cf130b28b5d`

Let's verify your current subscription:

```bash
az account show --query "{name:name, id:id}" -o table
```

---

## ✅ Next Steps

1. **Choose Option 1** (Ask admin to create service principal)
2. **Get the Client ID** from the admin
3. **Configure GitHub Secrets:**
   - `AZURE_CLIENT_ID`: `<from service principal creation>`
   - `AZURE_TENANT_ID`: `1033d128-85ad-47b4-8c85-0a28b6ce0297`
   - `AZURE_SUBSCRIPTION_ID`: `d7d7369b-a14f-43bc-a564-b4a077d170a9`

4. **Test GitHub Actions workflow**

Would you like me to help you with any of these approaches?
