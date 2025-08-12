# 📋 Quick Reference: Colleague Workflow for Resource Changes & Chaos Experiments

## 🚀 One-Time Setup (First Time Only)

```bash
# 1. Clone the repository
git clone https://github.com/CleveritDemo/AzureSREAgent.git
cd AzureSREAgent

# 2. Run automated setup script
.\colleague-setup.ps1

# 3. Configure GitHub Secrets (if using workflows)
# In GitHub repo settings > Secrets and variables > Actions:
# - AZURE_CLIENT_ID: Service Principal Application ID
# - AZURE_TENANT_ID: Azure AD Tenant ID  
# - AZURE_SUBSCRIPTION_ID: Target Azure Subscription ID

# That's it! You're ready to go! 🎉
```

## � Cross-Tenant/Cross-Subscription Migration

### **Complete Infrastructure Migration:**

```powershell
# Step 1: Validate prerequisites
.\validate-migration-prerequisites.ps1 -TargetTenantId "NEW_TENANT_ID" -TargetSubscriptionId "NEW_SUBSCRIPTION_ID"

# Step 2: Run migration (plan first)
.\migrate-to-new-tenant.ps1 `
    -TargetTenantId "NEW_TENANT_ID" `
    -TargetSubscriptionId "NEW_SUBSCRIPTION_ID" `
    -TargetResourceGroupName "eShopCleverRG" `
    -CreateStateBackend `
    -PlanOnly

# Step 3: Execute migration
.\migrate-to-new-tenant.ps1 `
    -TargetTenantId "NEW_TENANT_ID" `
    -TargetSubscriptionId "NEW_SUBSCRIPTION_ID" `
    -TargetResourceGroupName "eShopCleverRG" `
    -CreateStateBackend

# Step 4: Configure post-migration services
.\configure-post-migration.ps1 `
    -NewTenantId "NEW_TENANT_ID" `
    -NewSubscriptionId "NEW_SUBSCRIPTION_ID" `
    -CreateServicePrincipal `
    -GitHubRepo "CleveritDemo/AzureSREAgent"
```

### **Migration Features:**
- ✅ **Preserves all resource names and configurations**
- ✅ **Automated backup and rollback capabilities**
- ✅ **GitHub Actions integration with OIDC authentication**
- ✅ **Chaos experiment compatibility in new environment**
- ✅ **Comprehensive validation and verification**

## �🔄 Daily Workflow for Resource Changes

### **Making a Change:**

```bash
# 1. Navigate to terraform directory
cd terraform-export-clean

# 2. Pull latest changes from repository
git pull origin main

# 3. Edit the resource configuration
# Example: Edit main.tf to change ACR SKU from Basic to Standard

# 4. Preview your changes
terraform plan

# 5. Apply the changes (if plan looks good)
terraform apply

# 6. Verify the changes
terraform state show azurerm_container_registry.eshop_acr
```

## 🌪️ Chaos Experiment Management

### **Using GitHub Actions (Recommended):**

```bash
# 1. Go to GitHub Actions tab in repository
# 2. Select "Provision Chaos Experiment with Terraform"
# 3. Click "Run workflow" 
# 4. Fill in:
#    - Experiment Name: my-chaos-test
#    - Experiment Type: pod-failure | cpu-stress | memory-stress | network-delay | io-stress
#    - Duration: 300 (seconds)
#    - Dry Run: false (for actual provisioning)
# 5. Monitor workflow execution
```

### **Using PowerShell Scripts (Local):**

```powershell
# List current experiments
.\manage-chaos-experiments.ps1 -Action list

# Create new experiment  
.\manage-chaos-experiments.ps1 -Action create -ExperimentName "test-cpu-stress" -ExperimentType "cpu-stress"

# Delete experiment
.\manage-chaos-experiments.ps1 -Action delete -ExperimentName "test-cpu-stress"

# Sync remote state
.\manage-chaos-experiments.ps1 -Action sync-state

# Validate configuration
.\manage-chaos-experiments.ps1 -Action validate
```

### **Using Bash Scripts (Linux/WSL):**

```bash
# List current experiments
./manage-chaos-experiments.sh list

# Create new experiment
./manage-chaos-experiments.sh create test-network-delay network-delay

# Delete experiment  
./manage-chaos-experiments.sh delete test-network-delay

# Sync state
./manage-chaos-experiments.sh sync-state
```

### **Example Resource Change:**

```hcl
# In main.tf - Change ACR SKU
resource "azurerm_container_registry" "eshop_acr" {
  name                = "eshopcleveracr"
  resource_group_name = azurerm_resource_group.eshop_rg.name
  location           = azurerm_resource_group.eshop_rg.location
  sku                = "Standard"  # 🔄 Changed from "Basic"
  
  tags = {
    project     = "eshop"
    environment = var.environment
  }
}
```

## 🔐 Authentication & Security

### **GitHub Actions OIDC Configuration:**
- ✅ **Global OIDC Permissions**: Workflow has `id-token: write` permissions
- ✅ **Service Principal**: Uses Azure Service Principal with OIDC federation
- ✅ **Environment Variables**: ARM_USE_OIDC=true, ARM_USE_CLI=false configured
- ✅ **Remote State**: Authenticated access to Azure Storage backend

### **Local Development:**
```bash
# Verify authentication setup
.\test-terraform-auth.ps1  # PowerShell
./test-terraform-auth.sh   # Bash

# Expected result: ✅ All tests passed
```

## ⚠️ **Safety Checklist Before Every Change:**

- [ ] Communicated with team about the planned change
- [ ] Pulled latest code: `git pull origin main`
- [ ] Reviewed the change in `terraform plan`
- [ ] Confirmed no unexpected resource deletions
- [ ] Have rollback plan if needed
- [ ] **NEW**: For chaos experiments, ensure target resources are healthy

## 🛠️ **Common Change Scenarios:**

### **1. Change Resource Tags:**
```hcl
# In any resource block
tags = {
  project     = "eshop"
  environment = "production"  # 🔄 Changed value
  owner       = "team-alpha"  # ➕ Added new tag
}
```

### **2. Scale AKS Node Pool:**
```hcl
resource "azurerm_kubernetes_cluster" "eshop_aks" {
  # ... other configuration
  
  default_node_pool {
    name       = "default"
    node_count = 3  # 🔄 Changed from 2
    vm_size    = "Standard_D2_v2"
  }
}
```

### **3. Change SQL Database SKU:**
```hcl
resource "azurerm_mssql_database" "eshop_db" {
  # ... other configuration
  
  sku_name = "S1"  # 🔄 Changed from "Basic"
}
```

### **4. Update Container Registry Settings:**
```hcl
resource "azurerm_container_registry" "eshop_acr" {
  # ... other configuration
  
  sku                      = "Premium"     # 🔄 Upgraded SKU
  public_network_access    = "Disabled"    # 🔒 Enhanced security
  network_rule_bypass_option = "AzureServices"
}
```

### **5. Add New Chaos Experiment (Dynamic):**
```hcl
# Generated dynamically by GitHub Actions workflow
resource "azurerm_chaos_studio_experiment" "new_experiment" {
  location            = azurerm_resource_group.eshop_rg.location
  name                = "stress-test-cpu"
  resource_group_name = azurerm_resource_group.eshop_rg.name
  
  step {
    name = "stress-test-cpu-step"
    
    branch {
      name = "stress-test-cpu-branch"
      
      action {
        name     = "urn:csci:microsoft:azureKubernetesServiceChaosMesh:podChaos/1.2"
        duration = "PT5M"
        type     = "continuous"
        
        parameters = {
          podFailureRate = "0.5"
          targetPods     = "deployment/webmvc"
        }
        
        targets = [azurerm_chaos_studio_target.aks_cluster.id]
      }
    }
  }
  
  tags = {
    project = "eshop"
    type    = "chaos-experiment" 
    target  = "aks"
  }
}
```

## 🆘 **Emergency Commands:**

### **If Something Goes Wrong:**
```bash
# 1. Check current state
terraform state list

# 2. Refresh state to sync with Azure
terraform refresh

# 3. If you need to rollback
git log --oneline  # Find previous commit
git checkout <previous-commit-hash> -- main.tf
terraform plan     # Verify rollback plan
terraform apply    # Apply rollback
```

### **If State is Locked:**
```bash
# Check who has the lock
terraform plan
# Will show: "Error: state locked by user@domain.com"

# Wait for them to finish, or if urgent:
terraform force-unlock <LOCK_ID>  # ⚠️ Use with extreme caution!
```

### **Chaos Experiment Issues:**
```powershell
# Stop all running experiments
az rest --method POST --url "https://management.azure.com/subscriptions/$AZURE_SUBSCRIPTION_ID/resourceGroups/eShopCleverRG/providers/Microsoft.Chaos/experiments/{experiment-name}/cancel?api-version=2024-01-01"

# Check experiment status
.\manage-chaos-experiments.ps1 -Action list

# Remove problematic experiment from state
terraform state rm azurerm_chaos_studio_experiment.problematic_experiment

# Force refresh state
.\manage-chaos-experiments.ps1 -Action sync-state
```

### **GitHub Actions Workflow Issues:**
```bash
# Check workflow authentication
# Go to GitHub Actions > Provision Chaos Experiment > View logs
# Look for "Verify Authentication Method" step

# Common fixes:
# 1. Verify GitHub Secrets are set correctly
# 2. Check Service Principal permissions
# 3. Confirm OIDC federation is configured
# 4. Review ARM_* environment variables in logs
```

## 🎯 **Pro Tips:**

1. **Small Changes**: Make one change at a time
2. **Test First**: Use development.tfvars for testing
3. **Document**: Add comments explaining why you made changes
4. **Communicate**: Use team chat before major changes
5. **Backup**: State is automatically backed up, but document your changes
6. **NEW**: **Chaos Experiments**: Start with short durations (1-2 minutes) for testing
7. **NEW**: **Monitor**: Use Azure Monitor queries to track experiment impact
8. **NEW**: **Automation**: Prefer GitHub Actions for repeatable chaos experiments

## 📊 **Monitoring & Verification:**

### **Check Infrastructure Health:**
```bash
# Run health verification
.\verify-terraform-state.ps1

# Check specific resources
terraform state show azurerm_kubernetes_cluster.eshop_aks
terraform state show azurerm_chaos_studio_experiment.{name}
```

### **Monitor Chaos Experiments:**
```bash
# Use Azure Monitor queries (see azure-monitor-chaos-queries.kql)
# Check experiment execution logs
# Monitor target resource metrics during experiments
```

## 📞 **Need Help?**

- **Repository**: https://github.com/CleveritDemo/AzureSREAgent
- **Documentation**: 
  - `COLLEAGUE-ONBOARDING-GUIDE.md` - General setup
  - `chaos-experiments-guide.md` - Chaos experiment details
  - `WORKFLOW-AUTH-FIX-COMPLETE.md` - Authentication troubleshooting
  - `chaos-monitoring-guide.md` - Monitoring setup
- **Contact**: CleveritDemo team
- **Emergency**: Use verification scripts to check state health

## 🌟 **Latest Features:**

- ✅ **GitHub Actions Integration**: Automated chaos experiment provisioning
- ✅ **OIDC Authentication**: Secure, passwordless authentication
- ✅ **Dynamic Terraform Generation**: Experiments created on-demand
- ✅ **Remote State Sync**: Automatic state synchronization
- ✅ **Comprehensive Monitoring**: Azure Monitor integration
- ✅ **Multi-Platform Scripts**: PowerShell and Bash support

Your shared remote state in `eshopterraformstate8636` automatically keeps everything in sync! 🔄✨
