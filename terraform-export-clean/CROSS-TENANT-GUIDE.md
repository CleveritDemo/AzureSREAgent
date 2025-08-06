# Cross-Tenant/Cross-Subscription Deployment Guide

This guide helps you deploy eShopOnWeb infrastructure to a **different Azure subscription** and/or **different tenant**.

## 🎯 Prerequisites

1. **Access to target tenant/subscription** with appropriate permissions
2. **Azure CLI** installed and authenticated  
3. **Terraform** installed
4. **Contributor role** (or equivalent) in the target subscription

## 📋 Step-by-Step Setup

### Step 1: Identify Your Target Tenant and Subscription

#### Find Available Tenants
```powershell
# List all tenants you have access to
az account tenant list --output table
```

#### Login to Target Tenant
```powershell
# Login to specific tenant
az login --tenant "YOUR_TARGET_TENANT_ID"
```

#### Find Available Subscriptions in Target Tenant
```powershell
# List subscriptions in current tenant
az account list --output table
```

#### Get Detailed Information
```powershell
# Get current subscription and tenant details
az account show --query "{subscriptionId:id, tenantId:tenantId, name:name}" --output table
```

### Step 2: Create Custom Configuration File

1. **Copy the template**:
   ```powershell
   Copy-Item "cross-tenant-template.tfvars" "my-cross-tenant.tfvars"
   ```

2. **Edit the file** with your specific values:
   ```hcl
   # Azure Authentication Configuration
   subscription_id           = "12345678-1234-1234-1234-123456789012"  # Your target subscription ID
   tenant_id                = "87654321-4321-4321-4321-210987654321"  # Your target tenant ID
   
   # Resource Group Configuration  
   resource_group_name       = "eShop-CrossTenant-RG"                 # Unique name
   resource_group_location   = "West Europe"                          # Your preferred region
   
   # Project Configuration
   project_name             = "eshopct"                               # Short unique prefix
   environment              = "cross-tenant"                          # Environment tag
   
   # Security Configuration
   sql_admin_password       = "YourVerySecurePassword123!"            # Strong password
   ```

### Step 3: Validate Access and Permissions

```powershell
# Verify you can access the target subscription
az account set --subscription "YOUR_TARGET_SUBSCRIPTION_ID"
az account show

# Test resource group creation permissions (dry run)
az group create --name "test-permissions-rg" --location "West Europe" --dry-run
```

### Step 4: Deploy Using the Custom Configuration

#### Option A: Using the Deployment Script (Recommended)
```powershell
# Deploy with tenant and subscription switching
.\deploy-environment.ps1 -Environment custom -TfvarsFile "my-cross-tenant.tfvars" -TenantId "YOUR_TARGET_TENANT_ID" -SubscriptionId "YOUR_TARGET_SUBSCRIPTION_ID"

# Plan only first (recommended)
.\deploy-environment.ps1 -Environment custom -TfvarsFile "my-cross-tenant.tfvars" -TenantId "YOUR_TARGET_TENANT_ID" -SubscriptionId "YOUR_TARGET_SUBSCRIPTION_ID" -PlanOnly
```

#### Option B: Manual Terraform Commands
```powershell
# Login to target tenant
az login --tenant "YOUR_TARGET_TENANT_ID"

# Set target subscription
az account set --subscription "YOUR_TARGET_SUBSCRIPTION_ID"

# Initialize and deploy
terraform init
terraform plan -var-file="my-cross-tenant.tfvars"
terraform apply -var-file="my-cross-tenant.tfvars"
```

## 🔧 Configuration Examples

### Example 1: Different Subscription, Same Tenant
```hcl
subscription_id           = "new-subscription-id-here"
tenant_id                = "c9f150c3-1e99-4e8d-95fd-9a05ca65db01"  # Keep same tenant
resource_group_name       = "eShop-NewSub-RG"
resource_group_location   = "East US 2"
project_name             = "eshopnew"
environment              = "new-subscription"
sql_admin_password       = "NewSubPassword123!"
```

### Example 2: Different Tenant and Subscription
```hcl
subscription_id           = "different-tenant-subscription-id"
tenant_id                = "different-tenant-id-here"
resource_group_name       = "eShop-Partner-RG" 
resource_group_location   = "North Europe"
project_name             = "eshoppartner"
environment              = "partner-tenant"
sql_admin_password       = "PartnerPassword123!"
```

### Example 3: Production in Enterprise Tenant
```hcl
subscription_id           = "enterprise-prod-subscription-id"
tenant_id                = "enterprise-tenant-id"
resource_group_name       = "eShop-Enterprise-Prod"
resource_group_location   = "West US 2"
project_name             = "eshopent"
environment              = "enterprise-prod"
sql_admin_password       = "EnterpriseProdPassword123!"
```

## ⚠️ Important Considerations

### Security
- **Strong Passwords**: Use complex SQL admin passwords
- **Resource Naming**: Ensure resource names don't conflict
- **Permissions**: Verify you have Contributor role in target subscription

### Networking
- **Region Selection**: Choose regions close to your users
- **Compliance**: Consider data residency requirements
- **Connectivity**: Plan network connectivity if needed

### Cost Management
- **Resource Sizing**: Each environment incurs separate costs
- **Auto-shutdown**: Consider implementing auto-shutdown for dev/test
- **Monitoring**: Set up cost alerts in the target subscription

## 🎯 After Deployment

### Connect to Your New Infrastructure
```powershell
# Get outputs from Terraform
terraform output

# Connect to AKS cluster
az aks get-credentials --resource-group $(terraform output -raw resource_group_name) --name $(terraform output -raw aks_cluster_name)

# Verify AKS connection
kubectl get nodes

# Login to ACR
az acr login --name $(terraform output -raw container_registry_login_server | Split-Path -Leaf | Split-Path -LeafBase)
```

### Update Application Configuration
- **SQL Connection**: Update connection strings with new SQL server FQDN
- **Container Registry**: Update CI/CD pipelines with new ACR login server
- **AKS Context**: Update kubectl context for new cluster

## 🔄 Managing Multiple Environments

You can maintain multiple `.tfvars` files for different tenants/subscriptions:
- `production-tenant-a.tfvars`
- `development-tenant-b.tfvars`  
- `partner-tenant-c.tfvars`

Deploy to any of them using:
```powershell
.\deploy-environment.ps1 -Environment custom -TfvarsFile "production-tenant-a.tfvars"
```

## 🆘 Troubleshooting

### Authentication Issues
```powershell
# Clear cached credentials
az account clear

# Login fresh to target tenant
az login --tenant "YOUR_TARGET_TENANT_ID"

# Verify access
az account show
```

### Permission Issues
```powershell
# Check your role assignments
az role assignment list --assignee $(az account show --query user.name -o tsv) --output table
```

### Resource Conflicts
- Ensure ACR names are globally unique
- Verify resource group names don't exist
- Check SQL server name availability
