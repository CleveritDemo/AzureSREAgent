# eShopOnWeb Multi-Environment Deployment - Quick Reference

## 🚀 Quick Commands

### Deploy to Development
```powershell
.\deploy-environment.ps1 -Environment dev
```

### Deploy to Test
```powershell
.\deploy-environment.ps1 -Environment test
```

### Deploy to Production
```powershell
.\deploy-environment.ps1 -Environment prod
```

### Deploy to Different Subscription
```powershell
.\deploy-environment.ps1 -Environment prod -SubscriptionId "your-target-subscription-id"
```

### Plan Only (Review Changes)
```powershell
.\deploy-environment.ps1 -Environment dev -PlanOnly
```

### Destroy Environment
```powershell
.\deploy-environment.ps1 -Environment dev -Destroy
```

## 📋 Environment Configurations

| Environment | Resource Group | Location | Project Name | Example Resources |
|-------------|----------------|----------|--------------|-------------------|
| **Original** | eShopDemoSRErg | East US 2 | eshopsre | eshopsreacr, eshopsreaks |
| **Development** | eShopDevRG | East US | eshopdev | eshopdevacr, eshopdevaks |
| **Test** | eShopTestRG | West US 2 | eshoptest | eshoptestacr, eshoptestaks |
| **Production** | eShopProdRG | East US 2 | eshopprod | eshopprodacr, eshopprodaks |

## 🔧 Customizing Environments

Edit the `.tfvars` files to customize each environment:

- `development.tfvars` - Development settings
- `test.tfvars` - Test settings  
- `production.tfvars` - Production settings

### Example: Custom Configuration
```hcl
# Custom development configuration
subscription_id           = "your-dev-subscription-id"
resource_group_name       = "MyCompany-eShop-Dev"
resource_group_location   = "West Europe"
project_name             = "myeshopdev"
environment              = "development"
sql_admin_password       = "MySecurePassword123!"
```

## 🎯 After Deployment

### Connect to your new AKS cluster:
```bash
# Get cluster credentials
az aks get-credentials --resource-group $(terraform output -raw resource_group_name) --name $(terraform output -raw aks_cluster_name)

# Verify connection
kubectl get nodes
```

### Push images to your new ACR:
```bash
# Login to ACR
az acr login --name $(terraform output -raw container_registry_login_server | cut -d'.' -f1)

# Tag and push your images
docker tag eshopwebmvc:latest $(terraform output -raw container_registry_login_server)/eshopwebmvc:latest
docker push $(terraform output -raw container_registry_login_server)/eshopwebmvc:latest
```

### Update your application configuration:
- SQL Connection String: `Server=$(terraform output -raw sql_server_fqdn);Database=eshopdb;User Id=eshopsreadmin;Password=YourPassword;`
- Container Registry: `$(terraform output -raw container_registry_login_server)`

## ⚠️ Important Notes

1. **Costs**: Each environment creates separate Azure resources and will incur costs
2. **Security**: Update SQL passwords in production environments
3. **Cleanup**: Use the `-Destroy` flag to remove environments when not needed
4. **Subscriptions**: Ensure you have appropriate permissions in target subscriptions
