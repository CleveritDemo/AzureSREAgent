# 🎯 Cross-Tenant/Cross-Subscription Deployment - READY TO USE!

## ✅ What's Configured

Your Terraform configuration now supports **different subscriptions and tenants**:

### 🔧 Enhanced Configuration
- ✅ **Tenant Support**: Added `tenant_id` variable to main.tf
- ✅ **Subscription Support**: Enhanced `subscription_id` variable  
- ✅ **Dynamic Naming**: Resource names adapt to different environments
- ✅ **Custom Environments**: Support for unlimited environment configurations

### 📁 Files Ready for Use
- ✅ `my-custom.tfvars` - Your customizable configuration template
- ✅ `cross-tenant-template.tfvars` - Clean template for new environments  
- ✅ `deploy-environment.ps1` - Enhanced with tenant/subscription switching
- ✅ `find-subscriptions.ps1` - Discovery script for available resources
- ✅ `CROSS-TENANT-GUIDE.md` - Complete step-by-step guide

## 🚀 How to Deploy to Different Subscription/Tenant

### Step 1: Get Target Information
```powershell
# Discover available tenants and subscriptions
.\find-subscriptions.ps1

# Or manually check
az account tenant list --output table
az login --tenant "YOUR_TARGET_TENANT_ID"
az account list --output table
```

### Step 2: Customize Configuration
Edit `my-custom.tfvars` with your target values:
```hcl
subscription_id           = "YOUR_TARGET_SUBSCRIPTION_ID"
tenant_id                = "YOUR_TARGET_TENANT_ID"  
resource_group_name       = "YourUniqueResourceGroupName"
resource_group_location   = "Your Preferred Region"
project_name             = "yourprefix"  # Max 8 characters
sql_admin_password       = "YourSecurePassword123!"
```

### Step 3: Deploy
```powershell
# Easy deployment with automatic tenant/subscription switching
.\deploy-environment.ps1 -Environment custom -TfvarsFile "my-custom.tfvars" -TenantId "YOUR_TARGET_TENANT_ID" -SubscriptionId "YOUR_TARGET_SUBSCRIPTION_ID"

# Plan only first (recommended)
.\deploy-environment.ps1 -Environment custom -TfvarsFile "my-custom.tfvars" -TenantId "YOUR_TARGET_TENANT_ID" -SubscriptionId "YOUR_TARGET_SUBSCRIPTION_ID" -PlanOnly
```

## 📋 Example Configurations

### Current Setup (Reference)
```hcl
# Your current environment
subscription_id = "cab7669e-f28b-4420-8e9d-c8ad1634ce44"
tenant_id      = "c9f150c3-1e99-4e8d-95fd-9a05ca65db01"
# Creates: eshopctacr, eshopctaks, eshopct-sqlsrv in eShop-CrossTenant-RG
```

### Partner/Client Tenant Example
```hcl
subscription_id           = "partner-subscription-id-here"
tenant_id                = "partner-tenant-id-here"
resource_group_name       = "eShop-Partner-Production"
resource_group_location   = "North Europe"
project_name             = "eshopptr"
environment              = "partner-prod"
```

### Enterprise Production Example
```hcl
subscription_id           = "enterprise-prod-subscription-id"  
tenant_id                = "enterprise-tenant-id"
resource_group_name       = "eShop-Enterprise-Production"
resource_group_location   = "East US 2"
project_name             = "eshopent"
environment              = "enterprise"
```

## 🎯 Resource Naming Examples

| Configuration | ACR Name | AKS Name | SQL Server | Resource Group |
|---------------|----------|----------|------------|----------------|
| **Current Setup** | eshopctacr | eshopctaks | eshopct-sqlsrv | eShop-CrossTenant-RG |
| **Partner** | eshopptracr | eshopptraks | eshopptr-sqlsrv | eShop-Partner-Production |  
| **Enterprise** | eshopentacr | eshopentaks | eshopent-sqlsrv | eShop-Enterprise-Production |

## ⚠️ Important Notes

### Before Deployment
1. **Verify Access**: Ensure you have Contributor role in target subscription
2. **Check Naming**: Resource names must be globally unique (especially ACR)
3. **Choose Region**: Consider latency, compliance, and cost
4. **Strong Passwords**: Use complex SQL passwords

### Testing Access
```powershell
# Test permissions before deploying
az login --tenant "YOUR_TARGET_TENANT_ID"
az account set --subscription "YOUR_TARGET_SUBSCRIPTION_ID"
az group create --name "test-permissions-rg" --location "West Europe" --dry-run
```

### Cost Management
- Each environment creates separate billable resources
- Consider auto-shutdown for dev/test environments
- Set up cost alerts in target subscriptions

## 🔄 Managing Multiple Environments

You can create multiple `.tfvars` files for different scenarios:
```
my-production.tfvars     # Production environment
my-development.tfvars    # Development environment  
my-partner-a.tfvars      # Partner A tenant
my-partner-b.tfvars      # Partner B tenant
```

Deploy to any environment:
```powershell
.\deploy-environment.ps1 -Environment custom -TfvarsFile "my-production.tfvars"
```

## 📚 Documentation Reference

- 📖 **Complete Guide**: `CROSS-TENANT-GUIDE.md`
- 🚀 **Quick Reference**: `DEPLOYMENT-GUIDE.md`  
- 📋 **Main README**: `README.md`

## 🆘 Need Help?

1. **Discovery**: Run `.\find-subscriptions.ps1` to see available options
2. **Validation**: Run with `-PlanOnly` flag first
3. **Troubleshooting**: Check the `CROSS-TENANT-GUIDE.md` for common issues

## 🎉 You're Ready!

Your Terraform configuration is now **fully equipped** for cross-tenant and cross-subscription deployments. You can deploy eShopOnWeb infrastructure to any Azure subscription and tenant you have access to!
