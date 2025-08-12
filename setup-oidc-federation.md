# 🔐 Setup OIDC Federation for GitHub Actions

## 🎯 **Enable OIDC Federation for Service Principal**

This script will configure OIDC federation for your Service Principal to eliminate the need for password-based authentication.

### **📋 Prerequisites:**
- Service Principal: `github-actions-eshop-chaos` (App ID: `2e5ce55e-70e6-44b8-94b5-14f174babccd`)
- GitHub Repository: `CleveritDemo/AzureSREAgent`
- Azure CLI with appropriate permissions

### **🔧 Azure Admin Commands:**

```bash
# 1. Create federated credential for main branch
az ad app federated-credential create \
  --id "2e5ce55e-70e6-44b8-94b5-14f174babccd" \
  --parameters '{
    "name": "github-actions-main-branch",
    "issuer": "https://token.actions.githubusercontent.com",
    "subject": "repo:CleveritDemo/AzureSREAgent:ref:refs/heads/main",
    "description": "GitHub Actions OIDC for main branch",
    "audiences": ["api://AzureADTokenExchange"]
  }'

# 2. Create federated credential for pull requests
az ad app federated-credential create \
  --id "2e5ce55e-70e6-44b8-94b5-14f174babccd" \
  --parameters '{
    "name": "github-actions-pull-requests",
    "issuer": "https://token.actions.githubusercontent.com",
    "subject": "repo:CleveritDemo/AzureSREAgent:pull_request",
    "description": "GitHub Actions OIDC for pull requests",
    "audiences": ["api://AzureADTokenExchange"]
  }'

# 3. Create federated credential for any branch (optional - for flexibility)
az ad app federated-credential create \
  --id "2e5ce55e-70e6-44b8-94b5-14f174babccd" \
  --parameters '{
    "name": "github-actions-any-branch",
    "issuer": "https://token.actions.githubusercontent.com",
    "subject": "repo:CleveritDemo/AzureSREAgent:ref:refs/heads/*",
    "description": "GitHub Actions OIDC for any branch",
    "audiences": ["api://AzureADTokenExchange"]
  }'

# 4. Verify federated credentials created
az ad app federated-credential list --id "2e5ce55e-70e6-44b8-94b5-14f174babccd" --output table
```

### **📝 GitHub Repository Secrets Update:**

After creating the federated credentials, update your GitHub secrets:

**Keep these secrets:**
- `AZURE_CLIENT_ID` = `2e5ce55e-70e6-44b8-94b5-14f174babccd`
- `AZURE_TENANT_ID` = `1c8ef991-ec57-4212-b273-fb4e9ccd060d`
- `AZURE_SUBSCRIPTION_ID` = `d7d7369b-a14f-43bc-a564-b4a077d170a9`

**🗑️ Remove this secret (no longer needed):**
- ❌ Delete `AZURE_CLIENT_SECRET` - OIDC doesn't need passwords!

### **✅ Benefits of OIDC Federation:**

1. **🔒 Enhanced Security**: No stored passwords or secrets
2. **⏱️ Time-limited Tokens**: Tokens are short-lived and automatically rotated
3. **🎯 Precise Permissions**: Can be scoped to specific repositories and branches
4. **📊 Better Auditing**: Clear audit trail of authentication events
5. **🔄 No Secret Rotation**: No need to manage password expiration

### **🧪 Testing OIDC Authentication:**

Your GitHub Actions workflows are already configured for OIDC:
- ✅ `permissions: id-token: write` 
- ✅ `ARM_USE_OIDC: true`
- ✅ `ARM_USE_AZUREAD: true`

After setting up federation, test by running any workflow - it should authenticate without using `AZURE_CLIENT_SECRET`.

### **🔍 Troubleshooting:**

If authentication fails:

1. **Check Federated Credential Subject**: Ensure it matches your repository name exactly
2. **Verify Branch Name**: Main branch should be `refs/heads/main`
3. **Confirm App ID**: Use the Service Principal App ID, not Object ID
4. **Check Workflow Permissions**: Ensure `id-token: write` permission is set

### **📊 Verification Commands:**

```bash
# List all federated credentials for your Service Principal
az ad app federated-credential list --id "2e5ce55e-70e6-44b8-94b5-14f174babccd"

# Show details of a specific credential
az ad app federated-credential show \
  --id "2e5ce55e-70e6-44b8-94b5-14f174babccd" \
  --federated-credential-id "github-actions-main-branch"
```

---

**🎉 After OIDC Setup**: Your GitHub Actions will authenticate securely without passwords!
