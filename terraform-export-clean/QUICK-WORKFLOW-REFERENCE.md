# 📋 Quick Reference: Colleague Workflow for Resource Changes

## 🚀 One-Time Setup (First Time Only)

```bash
# 1. Clone the repository
git clone https://github.com/rodrigotraid/my-eshoponweb.git
cd my-eshoponweb

# 2. Run automated setup script
.\colleague-setup.ps1

# That's it! You're ready to go! 🎉
```

## 🔄 Daily Workflow for Resource Changes

### **Making a Change:**

```bash
# 1. Navigate to terraform directory
cd terraform-export-clean

# 2. Pull latest changes from repository
git pull origin main

# 3. Edit the resource configuration
# Example: Edit resources.tf to change ACR SKU from Basic to Standard

# 4. Preview your changes
terraform plan

# 5. Apply the changes (if plan looks good)
terraform apply

# 6. Verify the changes
terraform state show azurerm_container_registry.eshop_acr
```

### **Example Resource Change:**

```hcl
# In resources.tf - Change ACR SKU
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

## ⚠️ **Safety Checklist Before Every Change:**

- [ ] Communicated with team about the planned change
- [ ] Pulled latest code: `git pull origin main`
- [ ] Reviewed the change in `terraform plan`
- [ ] Confirmed no unexpected resource deletions
- [ ] Have rollback plan if needed

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

## 🆘 **Emergency Commands:**

### **If Something Goes Wrong:**
```bash
# 1. Check current state
terraform state list

# 2. Refresh state to sync with Azure
terraform refresh

# 3. If you need to rollback
git log --oneline  # Find previous commit
git checkout <previous-commit-hash> -- resources.tf
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

## 🎯 **Pro Tips:**

1. **Small Changes**: Make one change at a time
2. **Test First**: Use development.tfvars for testing
3. **Document**: Add comments explaining why you made changes
4. **Communicate**: Use team chat before major changes
5. **Backup**: State is automatically backed up, but document your changes

## 📞 **Need Help?**

- **Repository**: https://github.com/rodrigotraid/my-eshoponweb
- **Documentation**: `COLLEAGUE-ONBOARDING-GUIDE.md`
- **Contact**: rodrigotraid
- **Emergency**: Use verification scripts to check state health

Your shared remote state in `eshopterraformstate8636` automatically keeps everything in sync! 🔄✨
