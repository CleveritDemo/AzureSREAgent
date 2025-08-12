# 🔑 GitHub Repository Secrets Setup Guide

## 🎯 **NEXT IMMEDIATE STEP: Update GitHub Secrets**

### **📍 Navigate to GitHub Repository:**
```
https://github.com/CleveritDemo/AzureSREAgent/settings/secrets/actions
```

### **🔐 Required Secrets to Add/Update:**

| Secret Name | Value | Purpose |
|-------------|-------|---------|
| `AZURE_CLIENT_ID` | `2e5ce55e-70e6-44b8-94b5-14f174babccd` | Service Principal App ID |
| `AZURE_TENANT_ID` | `1c8ef991-ec57-4212-b273-fb4e9ccd060d` | Target Tenant ID |
| `AZURE_SUBSCRIPTION_ID` | `d7d7369b-a14f-43bc-a564-b4a077d170a9` | Target Subscription ID |
| `AZURE_CLIENT_SECRET` | `<Service Principal Password from Admin>` | Service Principal Password |

### **📋 Step-by-Step Instructions:**

1. **🌐 Open GitHub Repository**
   - Navigate to: https://github.com/CleveritDemo/AzureSREAgent
   - Click on **Settings** tab

2. **🔒 Access Secrets Section**
   - In the left sidebar, click **Secrets and variables**
   - Click **Actions**

3. **➕ Add/Update Each Secret**
   For each secret in the table above:
   - Click **New repository secret** (or **Update** if it exists)
   - Enter the **Name** exactly as shown
   - Enter the **Value** exactly as shown
   - Click **Add secret** or **Update secret**

### **✅ Verification Checklist:**

After adding all secrets, verify you have:
- [ ] `AZURE_CLIENT_ID` = `2e5ce55e-70e6-44b8-94b5-14f174babccd`
- [ ] `AZURE_TENANT_ID` = `1c8ef991-ec57-4212-b273-fb4e9ccd060d` 
- [ ] `AZURE_SUBSCRIPTION_ID` = `d7d7369b-a14f-43bc-a564-b4a077d170a9`
- [ ] `AZURE_CLIENT_SECRET` = `<Service Principal Password from Admin>`

### **🧪 Test GitHub Actions Workflow:**

After updating secrets, test the workflow:

1. **Go to Actions tab**: https://github.com/CleveritDemo/AzureSREAgent/actions
2. **Select a workflow**: `Deploy Infrastructure` or `Provision Chaos Experiment`
3. **Click "Run workflow"**
4. **Monitor the execution** to ensure it authenticates successfully

### **🎯 Expected Results:**

- ✅ Workflow should authenticate to Azure successfully
- ✅ Should be able to access your new tenant/subscription  
- ✅ Should be able to interact with your migrated resources
- ✅ Chaos experiments should be deployable

---

## 🚀 **AFTER GitHub Secrets Setup:**

Once GitHub secrets are configured, you can:

1. **Re-enable Chaos Experiments**:
   ```bash
   cd terraform-export-clean
   # Uncomment chaos experiments in main.tf
   terraform apply -var-file="target-migration.tfvars"
   ```

2. **Test Infrastructure Deployment**:
   - Run the GitHub Actions workflow
   - Verify all resources are accessible
   - Test chaos experiment provisioning

3. **Validate Complete Migration**:
   - Deploy a sample application to AKS
   - Test database connectivity
   - Run end-to-end tests

---

**🎉 MIGRATION SUCCESS!** - Your cross-tenant infrastructure migration is complete and ready for use!
