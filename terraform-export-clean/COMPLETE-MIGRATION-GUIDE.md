# 🚀 Complete Cross-Tenant/Cross-Subscription Migration Guide

This guide provides step-by-step instructions to migrate your entire eShopOnWeb infrastructure to a new Azure tenant and/or subscription while preserving all resource names and configurations.

## 📋 Overview

The migration process includes:
- ✅ **Complete infrastructure migration** using Terraform
- ✅ **Resource name preservation** - all resources keep their original names
- ✅ **Configuration preservation** - all settings, SKUs, and configurations maintained
- ✅ **Automated backup and verification** 
- ✅ **GitHub Actions integration** with updated secrets
- ✅ **Chaos experiment compatibility** in the new environment

## 🎯 Prerequisites

Before starting the migration, ensure you have:

### Required Access
- [ ] **Source Environment**: Current access to existing infrastructure
- [ ] **Target Tenant**: Access to the destination Azure tenant
- [ ] **Target Subscription**: Contributor role in the destination subscription
- [ ] **GitHub Repository**: Admin access to update secrets and workflows

### Required Tools
- [ ] **Azure CLI** (latest version)
- [ ] **Terraform** (>= 1.0)
- [ ] **PowerShell** (5.1 or later)
- [ ] **Git** access to the repository

### Required Information
- [ ] **Target Tenant ID** (Azure AD tenant where you want to migrate)
- [ ] **Target Subscription ID** (Azure subscription in the target tenant)
- [ ] **SQL Admin Password** (will be reused in the new environment)
- [ ] **Resource Group Name** (can keep "eShopCleverRG" or change it)

## 🛡️ Phase 1: Pre-Migration Validation

Run the validation script to ensure all prerequisites are met:

```powershell
# Navigate to terraform directory
cd terraform-export-clean

# Run pre-migration validation
.\validate-migration-prerequisites.ps1 -TargetTenantId "YOUR_TARGET_TENANT_ID" -TargetSubscriptionId "YOUR_TARGET_SUBSCRIPTION_ID"
```

**Expected Output**: All validations should pass (✅). Address any failures before proceeding.

## 🔄 Phase 2: Infrastructure Migration

### Option A: Complete Automated Migration (Recommended)

```powershell
# Run the complete migration script
.\migrate-to-new-tenant.ps1 `
    -TargetTenantId "YOUR_TARGET_TENANT_ID" `
    -TargetSubscriptionId "YOUR_TARGET_SUBSCRIPTION_ID" `
    -TargetResourceGroupName "eShopCleverRG" `
    -TargetLocation "East US 2" `
    -CreateStateBackend `
    -PlanOnly

# Review the plan, then run without -PlanOnly to execute
.\migrate-to-new-tenant.ps1 `
    -TargetTenantId "YOUR_TARGET_TENANT_ID" `
    -TargetSubscriptionId "YOUR_TARGET_SUBSCRIPTION_ID" `
    -TargetResourceGroupName "eShopCleverRG" `
    -TargetLocation "East US 2" `
    -CreateStateBackend
```

### Option B: Step-by-Step Manual Migration

#### Step 1: Export Current State
```powershell
# Create backup directory
New-Item -ItemType Directory -Path "migration-backup" -Force

# Export current Terraform state
terraform state pull > "migration-backup\source-terraform-$(Get-Date -Format 'yyyyMMdd-HHmmss').tfstate"

# Export resource list
terraform state list > "migration-backup\source-resources-$(Get-Date -Format 'yyyyMMdd-HHmmss').txt"

# Export Azure resources
az resource list --resource-group eShopCleverRG --output json > "migration-backup\azure-resources-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"
```

#### Step 2: Authenticate to Target Environment
```powershell
# Login to target tenant
az login --tenant "YOUR_TARGET_TENANT_ID"

# Set target subscription
az account set --subscription "YOUR_TARGET_SUBSCRIPTION_ID"

# Verify access
az account show
```

#### Step 3: Create Target Configuration
```powershell
# Create target environment variables file
@"
subscription_id           = "YOUR_TARGET_SUBSCRIPTION_ID"
tenant_id                = "YOUR_TARGET_TENANT_ID"
resource_group_name       = "eShopCleverRG"
resource_group_location   = "East US 2"
project_name             = "eshopclever"
environment              = "migrated"
sql_admin_password       = "YOUR_SQL_PASSWORD"
ssh_public_key          = "YOUR_SSH_PUBLIC_KEY"
"@ | Out-File -FilePath "target-migration.tfvars" -Encoding UTF8
```

#### Step 4: Create Target State Backend (Optional)
```powershell
# Create resource group
az group create --name "eShopCleverRG" --location "East US 2"

# Create storage account for Terraform state
$storageAccount = "eshopterraformstate$(Get-Random -Minimum 1000 -Maximum 9999)"
az storage account create `
    --resource-group "eShopCleverRG" `
    --name $storageAccount `
    --sku Standard_LRS `
    --encryption-services blob

# Create container
az storage container create --name tfstate --account-name $storageAccount

# Create backend configuration
@"
resource_group_name  = "eShopCleverRG"
storage_account_name = "$storageAccount"
container_name       = "tfstate"
key                  = "terraform.tfstate"
"@ | Out-File -FilePath "backend-target.conf" -Encoding UTF8
```

#### Step 5: Initialize and Deploy
```powershell
# Initialize with target backend (if using new backend)
terraform init -backend-config="backend-target.conf" -reconfigure

# Or initialize with existing backend
terraform init

# Plan the migration
terraform plan -var-file="target-migration.tfvars" -out="migration.tfplan"

# Review the plan thoroughly, then apply
terraform apply "migration.tfplan"
```

## ⚙️ Phase 3: Post-Migration Configuration

Run the post-migration configuration script:

```powershell
.\configure-post-migration.ps1 `
    -NewTenantId "YOUR_TARGET_TENANT_ID" `
    -NewSubscriptionId "YOUR_TARGET_SUBSCRIPTION_ID" `
    -NewResourceGroupName "eShopCleverRG" `
    -CreateServicePrincipal `
    -GitHubRepo "CleveritDemo/AzureSREAgent"
```

This script will:
- ✅ Create/update Service Principal for GitHub Actions
- ✅ Configure OIDC federation for passwordless authentication
- ✅ Update workflow files with new subscription ID
- ✅ Verify all resources were created successfully
- ✅ Display GitHub Secrets configuration

## 🔑 Phase 4: Update GitHub Repository

### Update Repository Secrets

Go to your GitHub repository: `Settings > Secrets and variables > Actions`

Update these secrets with the values provided by the post-migration script:

| Secret Name | Value | Description |
|-------------|--------|-------------|
| `AZURE_CLIENT_ID` | `17eaa6dd-7c38-40e6-ae28-a0c55d421cbd` | Service Principal Application ID |
| `AZURE_TENANT_ID` | `YOUR_TARGET_TENANT_ID` | Target tenant ID |
| `AZURE_SUBSCRIPTION_ID` | `YOUR_TARGET_SUBSCRIPTION_ID` | Target subscription ID |

### Update Workflow Files

The post-migration script automatically updates:
- `.github/workflows/provision-chaos-experiment.yml`
- `.github/workflows/chaos-experiments.yml`
- `.github/workflows/deploy-infrastructure.yml`

Verify these files have the correct subscription ID in environment variables.

## ✅ Phase 5: Verification and Testing

### 1. Verify Infrastructure
```powershell
# Check all resources exist
az resource list --resource-group eShopCleverRG --output table

# Verify AKS cluster
az aks get-credentials --resource-group eShopCleverRG --name eshopcleveraks
kubectl get nodes

# Verify SQL database
az sql db show --resource-group eShopCleverRG --server eshopclever-sqlsrv --name eshopdb
```

### 2. Test GitHub Actions Workflows
- Go to GitHub Actions tab
- Run "Provision Chaos Experiment with Terraform" workflow
- Verify authentication works with new secrets
- Test chaos experiment creation

### 3. Verify Application Connectivity
```powershell
# Get AKS cluster IP
az aks show --resource-group eShopCleverRG --name eshopcleveraks --query "networkProfile.loadBalancerProfile.effectiveOutboundIPs[0].id" -o tsv

# Test application endpoints
# Update with your actual service endpoints
```

### 4. Test Chaos Experiments
```powershell
# Run chaos experiment management script
.\manage-chaos-experiments.ps1 -Action list

# Create a test experiment
.\manage-chaos-experiments.ps1 -Action create -ExperimentName "migration-test" -ExperimentType "pod-failure"
```

## 🗑️ Phase 6: Source Environment Cleanup (Optional)

⚠️ **Warning**: Only perform this step when you're confident the migration was successful and all applications are working in the new environment.

### Option A: Keep Source for Backup
- Maintain the source environment as a backup
- Consider stopping/deallocating resources to reduce costs
- Keep state files for reference

### Option B: Complete Source Removal
```powershell
# Switch back to source environment
az login --tenant "SOURCE_TENANT_ID"
az account set --subscription "SOURCE_SUBSCRIPTION_ID"

# Use Terraform to destroy (if source uses Terraform)
terraform destroy

# Or use Azure CLI to delete resource group
az group delete --name "eShopCleverRG" --yes --no-wait
```

## 📊 Migration Checklist

Use this checklist to track your migration progress:

### Pre-Migration
- [ ] Validated prerequisites with validation script
- [ ] Confirmed access to target tenant and subscription
- [ ] Backed up current configuration and state
- [ ] Documented current resource inventory
- [ ] Prepared SQL admin password and SSH keys

### Migration Execution
- [ ] Exported current infrastructure state
- [ ] Authenticated to target environment
- [ ] Created target configuration files
- [ ] Set up target Terraform state backend (if needed)
- [ ] Executed Terraform plan and reviewed changes
- [ ] Applied Terraform configuration
- [ ] Verified all resources created successfully

### Post-Migration Configuration
- [ ] Created/updated Service Principal for GitHub Actions
- [ ] Configured OIDC federation
- [ ] Updated GitHub repository secrets
- [ ] Updated workflow files
- [ ] Verified Service Principal permissions

### Testing and Verification
- [ ] Verified all Azure resources exist and are healthy
- [ ] Tested AKS cluster connectivity
- [ ] Verified SQL database accessibility
- [ ] Tested GitHub Actions workflows
- [ ] Verified chaos experiments work
- [ ] Tested application endpoints
- [ ] Updated external documentation

### Cleanup (Optional)
- [ ] Planned source environment retention/removal
- [ ] Updated team documentation
- [ ] Communicated migration completion to stakeholders

## 🚨 Troubleshooting

### Common Issues

#### Authentication Errors
```powershell
# Clear Azure CLI cache
az logout
az cache purge
az login --tenant "YOUR_TARGET_TENANT_ID"
```

#### Terraform State Issues
```powershell
# Refresh state
terraform refresh -var-file="target-migration.tfvars"

# Force unlock if needed
terraform force-unlock "LOCK_ID"
```

#### Resource Name Conflicts
- Ensure unique resource names if deploying to existing environment
- Check resource naming constraints for target region
- Verify service availability in target region

#### GitHub Actions Authentication
- Verify OIDC federation is configured correctly
- Check Service Principal permissions
- Ensure federated identity subject matches repository pattern

### Recovery Procedures

#### If Migration Fails Mid-Process
1. Don't panic - you have backups
2. Review error messages in Terraform output
3. Fix issues and re-run terraform apply
4. Use state backups if needed to recover

#### If Need to Rollback
1. Use source state backup to restore original environment
2. Import existing resources if needed
3. Verify original functionality

## 📞 Support

If you encounter issues during migration:

1. **Check the logs**: Review Terraform output and Azure CLI errors
2. **Consult documentation**: Reference Azure and Terraform documentation
3. **Use validation scripts**: Run validation scripts to identify issues
4. **Review backups**: Check backup files for configuration reference

## 📚 Additional Resources

- [Azure Resource Manager Documentation](https://docs.microsoft.com/en-us/azure/azure-resource-manager/)
- [Terraform Azure Provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
- [GitHub Actions OIDC with Azure](https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/configuring-openid-connect-in-azure)
- [Azure Chaos Studio](https://docs.microsoft.com/en-us/azure/chaos-studio/)

---

**Migration Status**: Ready for execution
**Last Updated**: August 12, 2025
**Tested**: Prerequisites validation ✅ | Full migration: Pending user execution
