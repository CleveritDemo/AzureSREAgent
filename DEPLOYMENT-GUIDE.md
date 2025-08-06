# 🚀 eShopOnWeb Container Apps Deployment Guide
# ===============================================

## ✅ Prerequisites Status
- [x] Azure CLI: v2.75.0 (Ready)
- [x] Docker: v27.3.1 (Ready)
- [x] Azure Developer CLI: Installed (Restart Terminal Required)

## 🔧 Setup Steps

### 1. **Restart Your Terminal/PowerShell**
After installing azd, you need to restart your terminal to update the PATH environment variable.

```powershell
# Close this terminal and open a new PowerShell window, then verify:
azd version
```

### 2. **Initialize AZD Environment**
```powershell
# Navigate to your project directory
cd "c:\Users\rodri\eShopOnWeb"

# Initialize azd for this project
azd init --template .

# Set your environment name
azd env new eshop-demo
```

### 3. **Configure Your Deployment**
```powershell
# Set the required environment variables
azd env set AZURE_LOCATION "eastus"
azd env set AZURE_PRINCIPAL_ID $(az ad signed-in-user show --query id -o tsv)
```

### 4. **Deploy to Azure**
```powershell
# Deploy infrastructure and applications
azd up
```

## 📋 What AZD Will Deploy

### 🏗️ Infrastructure:
- **Resource Group**: `rg-eshop-demo`
- **Container Registry**: For your Docker images
- **Container Apps Environment**: With logging and monitoring
- **Key Vault**: For secure connection strings
- **Log Analytics & Application Insights**: For monitoring
- **User-Assigned Managed Identity**: For secure access

### 🐳 Applications:
- **Web MVC**: Your eShop frontend
- **Public API**: Your eShop API backend

### 🔐 Security:
- SQL connection strings stored in Key Vault
- Managed Identity for ACR access
- CORS enabled for web traffic

## 🎯 Alternative Manual Deployment

If you prefer manual deployment, you can use Azure CLI:

```powershell
# Create resource group
az group create --name "rg-eshop-demo" --location "eastus"

# Deploy Bicep template
az deployment group create \
  --resource-group "rg-eshop-demo" \
  --template-file "infra/main.bicep" \
  --parameters "infra/main.parameters.json" \
  --parameters environmentName="eshop-demo" \
  --parameters location="eastus" \
  --parameters principalId=$(az ad signed-in-user show --query id -o tsv)
```

## 🔄 Update Your Container Images

After deployment, update your container apps to use your built images:

```powershell
# Get your container registry name
$acrName = az deployment group show --resource-group "rg-eshop-demo" --name "main" --query "properties.outputs.AZURE_CONTAINER_REGISTRY_NAME.value" -o tsv

# Update web MVC container app
az containerapp update \
  --name "ca-webmvc-[unique-id]" \
  --resource-group "rg-eshop-demo" \
  --image "$acrName.azurecr.io/eshopwebmvc:latest"

# Update public API container app  
az containerapp update \
  --name "ca-publicapi-[unique-id]" \
  --resource-group "rg-eshop-demo" \
  --image "$acrName.azurecr.io/eshoppublicapi:latest"
```

## 📊 Monitor Your Deployment

After deployment, you can:
- View logs in Application Insights
- Monitor performance in Azure Portal
- Access your applications via the provided URLs

## 🆘 Troubleshooting

### If azd command not found:
1. Restart your terminal completely
2. Or manually add to PATH: `$env:PATH += ";C:\Program Files\Azure Dev CLI\bin"`

### If deployment fails:
1. Check Azure CLI is logged in: `az account show`
2. Verify permissions in your subscription
3. Check the deployment logs in Azure Portal

## 🎉 Success Indicators

When deployment completes successfully:
- ✅ Resource group created with all resources
- ✅ Container apps running and accessible
- ✅ Database connections working
- ✅ Applications available at public URLs

Your eShopOnWeb application will be running on Azure Container Apps with secure database connections! 🚀
