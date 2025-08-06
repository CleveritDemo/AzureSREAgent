# eShopOnWeb Azure Infrastructure - Terraform Configuration

This Terraform configuration recreates the Azure infrastructure for the eShopOnWeb application with support for multiple environments and subscriptions.

## 🎯 Multi-Environment Support

This configuration supports deploying to different environments:
- **Original**: Matches your existing infrastructure exactly
- **Development**: Creates dev environment with different resource names
- **Test**: Creates test environment in different location
- **Production**: Creates production environment with prod naming

## Resources Created

Based on the environment, creates:
- **Resource Group**: Configurable name and location
- **Container Registry**: `{project_name}acr` (e.g., `eshopdevacr`)
- **SQL Server**: `{project_name}-sqlsrv` (e.g., `eshopdev-sqlsrv`)
- **SQL Database**: `eshopdb` (consistent across environments)
- **AKS Cluster**: `{project_name}aks` (e.g., `eshopdevaks`)

## Prerequisites

1. Azure CLI installed and authenticated (`az login`)
2. Terraform >= 1.0 installed
3. Appropriate Azure permissions to create resources
4. PowerShell (for deployment scripts)

## 🚀 Quick Start

### Option 1: Easy Deployment (Recommended)
Use the PowerShell deployment script:

```powershell
# Deploy to development environment
.\deploy-environment.ps1 -Environment dev

# Deploy to test environment  
.\deploy-environment.ps1 -Environment test

# Deploy to production environment
.\deploy-environment.ps1 -Environment prod

# Deploy original configuration (matches existing resources)
.\deploy-environment.ps1 -Environment original

# Plan only (review changes without applying)
.\deploy-environment.ps1 -Environment dev -PlanOnly

# Destroy environment
.\deploy-environment.ps1 -Environment dev -Destroy
```

### Option 2: Manual Deployment

#### 1. Initialize Terraform
```bash
terraform init
```

#### 2. Choose Your Environment

**For Development Environment:**
```bash
terraform plan -var-file="development.tfvars"
terraform apply -var-file="development.tfvars"
```

**For Test Environment:**
```bash
terraform plan -var-file="test.tfvars"
terraform apply -var-file="test.tfvars"
```

**For Production Environment:**
```bash
terraform plan -var-file="production.tfvars"
terraform apply -var-file="production.tfvars"
```

**For Original Configuration:**
```bash
terraform plan
terraform apply
```

### 4. Get Outputs
```bash
terraform output
```

## Variables

- `sql_admin_password`: SQL Server administrator password (default: "_Matilde11")
- `ssh_public_key`: SSH public key for AKS nodes (uses your current key)

## Important Notes

### Security Considerations
- The SQL firewall rule allows all IPs (0.0.0.0-255.255.255.255) for demo purposes
- In production, restrict this to specific IP ranges
- Store passwords securely using Azure Key Vault or environment variables

### Network Configuration
- AKS uses Azure CNI with overlay networking
- Pod CIDR: 10.244.0.0/16
- Service CIDR: 10.0.0.0/16

### ACR Integration
- AKS has AcrPull role assignment to the Container Registry
- This allows AKS to pull images from ACR without additional authentication

## Connecting to Resources

### AKS Cluster
```bash
# Get credentials
az aks get-credentials --resource-group eShopDemoSRErg --name eshopsreaks

# Verify connection
kubectl get nodes
```

### SQL Database
```bash
# Connection string format
Server=eshopsre-sqlsrv.database.windows.net;Database=eshopdb;User Id=eshopsreadmin;Password=_Matilde11;
```

### Container Registry
```bash
# Login to ACR
az acr login --name eshopsreacr

# Push/pull images
docker push eshopsreacr.azurecr.io/your-image:tag
```

## Cleanup

To destroy all resources:
```bash
terraform destroy
```

## 📁 Configuration Files

- `main.tf` - Provider configuration with subscription support
- `resources.tf` - Main resource definitions with variables
- `variables.tf` - Variable declarations with defaults  
- `outputs.tf` - Output values for all environments
- `README.md` - This documentation
- `deploy-environment.ps1` - PowerShell deployment script

### Environment Files (.tfvars)
- `development.tfvars` - Development environment settings
- `test.tfvars` - Test environment settings  
- `production.tfvars` - Production environment settings

## 🔧 Configuration Variables

| Variable | Description | Default | Example |
|----------|-------------|---------|---------|
| `subscription_id` | Azure subscription ID | Current subscription | `cab7669e-f28b-4420-8e9d-c8ad1634ce44` |
| `resource_group_name` | Resource group name | `eShopDemoSRErg` | `eShopProdRG` |
| `resource_group_location` | Resource group location | `East US 2` | `West US 2` |
| `project_name` | Resource name prefix | `eshopsre` | `eshopprod` |
| `environment` | Environment tag | `demo` | `prod` |
| `sql_admin_password` | SQL admin password | `_Matilde11` | `YourSecurePassword123!` |

## 🔐 Multi-Subscription Support

To deploy to a different subscription:

1. **Update the .tfvars file** with your target subscription ID:
```hcl
subscription_id = "your-target-subscription-id"
```

2. **Switch to the target subscription:**
```bash
az account set --subscription "your-target-subscription-id"
```

3. **Deploy using the script:**
```powershell
.\deploy-environment.ps1 -Environment prod -SubscriptionId "your-target-subscription-id"
```

## Troubleshooting

1. **Authentication Issues**: Ensure you're logged in with `az login`
2. **Permission Issues**: Verify your account has Contributor role on the subscription
3. **Resource Conflicts**: If resources already exist, you may need to import them first
4. **Version Issues**: Update to the latest Terraform AzureRM provider

## Original vs Terraform Resources

This configuration matches your existing Azure resources:
- Same names and locations
- Same SKUs and configurations
- Same network settings
- Maintains existing functionality
