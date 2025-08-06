# 👥 Colleague Onboarding Guide: Working with Shared Terraform Remote State

## 🎯 Overview
Your colleague needs to configure their local environment to connect to the same remote state backend that manages your Azure resources.

## 📋 Prerequisites Checklist

### 🔑 **Azure Access Requirements:**
- [ ] Azure subscription access: `5f62fee3-b00a-44d2-86e5-5cf130b28b5d`
- [ ] Resource Group access: `eShopCleverRG`
- [ ] Storage Account access: `eshopterraformstate8636`
- [ ] RBAC roles: Contributor or Owner on the resource group
- [ ] Azure CLI installed and configured

### 🛠️ **Local Environment Setup:**
- [ ] Terraform CLI installed (same version recommended)
- [ ] Git access to your repository
- [ ] VS Code or preferred IDE
- [ ] PowerShell (for Windows) or equivalent shell

## 🚀 Step-by-Step Setup Process

### **Step 1: Clone the Repository**
```bash
git clone https://github.com/rodrigotraid/my-eshoponweb.git
cd my-eshoponweb
```

### **Step 2: Azure Authentication**
```bash
# Login to Azure
az login

# Set the correct subscription
az account set --subscription "5f62fee3-b00a-44d2-86e5-5cf130b28b5d"

# Verify access
az account show
```

### **Step 3: Navigate to Terraform Directory**
```bash
cd terraform-export-clean
```

### **Step 4: Verify Backend Configuration**
Check that `backend.tf` exists and contains:
```hcl
terraform {
  backend "azurerm" {
    resource_group_name  = "eShopCleverRG"
    storage_account_name = "eshopterraformstate8636"
    container_name       = "tfstate"
    key                  = "terraform.tfstate"
  }
}
```

### **Step 5: Initialize Terraform with Remote Backend**
```bash
# This connects to the shared remote state
terraform init
```

**Expected Output:**
```
Initializing the backend...
Successfully configured the backend "azurerm"!
Terraform has been successfully initialized!
```

### **Step 6: Verify State Access**
```bash
# List resources in shared state
terraform state list

# Show current plan (should show "No changes")
terraform plan
```

**Expected Resources:**
- azurerm_resource_group.eshop_rg
- azurerm_container_registry.eshop_acr
- azurerm_kubernetes_cluster.eshop_aks
- azurerm_mssql_server.eshop_sql_server
- azurerm_mssql_database.eshop_db
- azurerm_mssql_firewall_rule.allow_all

## 🔧 Making Changes to Existing Resources

### **Method 1: Direct Terraform Configuration Changes**

1. **Edit the resource configuration** in the `.tf` files:
```hcl
# Example: Changing ACR SKU in resources.tf
resource "azurerm_container_registry" "eshop_acr" {
  name                = "eshopcleveracr"
  resource_group_name = azurerm_resource_group.eshop_rg.name
  location           = azurerm_resource_group.eshop_rg.location
  sku                = "Standard"  # Changed from "Basic"
  # ... other configuration
}
```

2. **Preview the changes:**
```bash
terraform plan
```

3. **Apply the changes:**
```bash
terraform apply
```

### **Method 2: Using Environment-Specific Variables**

1. **Create or modify environment files:**
```bash
# For development changes
code development.tfvars

# For production changes  
code production.tfvars
```

2. **Apply with specific variables:**
```bash
# Development environment
terraform plan -var-file="development.tfvars"
terraform apply -var-file="development.tfvars"

# Production environment
terraform plan -var-file="production.tfvars"
terraform apply -var-file="production.tfvars"
```

## ⚠️ **Important Safety Practices**

### **Before Making Changes:**

1. **Always run plan first:**
```bash
terraform plan
```

2. **Review the changes carefully:**
   - What resources will be modified?
   - Are there any destructive operations?
   - Is this the intended change?

3. **Coordinate with team:**
   - Inform team members about planned changes
   - Check if anyone else is making modifications
   - Consider using branch protection for critical changes

### **During Changes:**

1. **Use state locking (automatic):**
   - Terraform automatically locks the state during apply
   - Other team members will see "state locked" message
   - Wait for lock release before proceeding

2. **Monitor the apply process:**
   - Watch for errors or unexpected behavior
   - Be ready to interrupt if something goes wrong

### **After Changes:**

1. **Verify the changes:**
```bash
# Check the specific resource
terraform state show azurerm_container_registry.eshop_acr

# Verify in Azure Portal
az resource show --resource-group eShopCleverRG --name eshopcleveracr --resource-type Microsoft.ContainerRegistry/registries
```

2. **Test the infrastructure:**
   - Verify applications still work
   - Check connectivity and functionality
   - Run any automated tests

## 🔒 **State Locking and Collaboration**

### **If State is Locked:**
```bash
# Check who has the lock
terraform plan
# Output will show: "Error: state locked by user@domain.com"

# If you need to force unlock (DANGEROUS - use with caution)
terraform force-unlock LOCK_ID
```

### **Best Practices for Team Collaboration:**
1. **Communicate changes** in team chat before applying
2. **Use feature branches** for infrastructure changes
3. **Implement code reviews** for Terraform changes
4. **Schedule maintenance windows** for major changes
5. **Keep changes small and focused**

## 🛠️ **Useful Commands for Your Colleague**

### **Environment Management:**
```bash
# Switch between environments using backend configs
terraform init -backend-config="backend-dev.conf"
terraform init -backend-config="backend-prod.conf"
terraform init -backend-config="backend-test.conf"
```

### **State Management:**
```bash
# List all resources
terraform state list

# Show specific resource details  
terraform state show azurerm_container_registry.eshop_acr

# Import existing resources (if needed)
terraform import azurerm_resource_group.example /subscriptions/xxx/resourceGroups/xxx

# Backup current state
terraform state pull > backup.tfstate
```

### **Validation and Planning:**
```bash
# Validate configuration syntax
terraform validate

# Format code consistently
terraform fmt

# Plan with detailed output
terraform plan -detailed-exitcode

# Plan and save to file
terraform plan -out=plan.tfplan
terraform apply plan.tfplan
```

## 🚨 **Troubleshooting Common Issues**

### **Issue 1: Authentication Errors**
```bash
# Re-authenticate with Azure
az login --tenant c9f150c3-1e99-4e8d-95fd-9a05ca65db01
az account set --subscription "5f62fee3-b00a-44d2-86e5-5cf130b28b5d"
```

### **Issue 2: State Access Denied**
```bash
# Check storage account permissions
az role assignment list --assignee $(az account show --query user.name -o tsv) --scope /subscriptions/5f62fee3-b00a-44d2-86e5-5cf130b28b5d/resourceGroups/eShopCleverRG/providers/Microsoft.Storage/storageAccounts/eshopterraformstate8636
```

### **Issue 3: Provider Version Conflicts**
```bash
# Update provider lock file
terraform providers lock -platform=windows_amd64 -platform=linux_amd64 -platform=darwin_amd64
```

### **Issue 4: State Drift Detection**
```bash
# Refresh state to sync with actual Azure resources
terraform refresh

# Compare state with actual resources
terraform plan -refresh-only
```

## 📞 **Getting Help**

### **Emergency Contacts:**
- **Primary Owner:** rodrigotraid
- **Repository:** https://github.com/rodrigotraid/my-eshoponweb
- **Documentation:** Check the terraform-export-clean/README.md

### **Useful Scripts in Repository:**
- `verify-terraform-state.ps1` - Verify state consistency
- `state-analysis.ps1` - Advanced state analysis
- `manage-terraform-state.ps1` - State management utilities
- `deploy-with-backend.ps1` - Automated deployment

## ✅ **Quick Start Checklist for Your Colleague**

- [ ] Clone repository
- [ ] Install Azure CLI and Terraform
- [ ] Authenticate with Azure (`az login`)
- [ ] Set correct subscription
- [ ] Navigate to `terraform-export-clean/`
- [ ] Run `terraform init`
- [ ] Run `terraform plan` to verify access
- [ ] Make configuration changes
- [ ] Run `terraform plan` to preview
- [ ] Run `terraform apply` to implement
- [ ] Verify changes in Azure Portal
- [ ] Document changes and notify team

Your colleague is now ready to safely modify the shared Terraform-managed resources! 🚀
