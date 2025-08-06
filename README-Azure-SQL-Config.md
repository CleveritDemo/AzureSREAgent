# eShopOnWeb Azure SQL Configuration - Quick Reference
# ===================================================

## ✅ Connection Configuration Complete!

Your Azure SQL Database is **ONLINE** and connection strings have been configured.

### 📁 Created Configuration Files:

| File | Purpose | Environment |
|------|---------|-------------|
| `appsettings.Production.json` | Environment variables approach | `ASPNETCORE_ENVIRONMENT=Production` |
| `appsettings.AzureDirect.json` | Direct connection strings | `ASPNETCORE_ENVIRONMENT=AzureDirect` |
| `appsettings.Azure.json` | Key Vault references | `ASPNETCORE_ENVIRONMENT=Azure` |
| `.env.deployment` | Deployment variables reference | Documentation |

### 🚀 Next Steps Options:

#### Option 1: Quick Test with AzureDirect Environment
```bash
# Set environment and rebuild images
$env:ASPNETCORE_ENVIRONMENT="AzureDirect"
.\build-and-push.ps1
```

#### Option 2: Production with Environment Variables
```bash
# Deploy to App Service/Container Apps with these environment variables:
SQL_SERVER_PASSWORD=_Matilde11
ASPNETCORE_ENVIRONMENT=Production
API_BASE_URL=https://your-api-domain.azurewebsites.net/api/
WEB_BASE_URL=https://your-web-domain.azurewebsites.net/
```

#### Option 3: Container Runtime Environment Variables
```bash
# For Docker/Container Apps, use .NET configuration pattern:
CONNECTIONSTRINGS__CATALOGCONNECTION="Server=eshopsre-sqlsrv.database.windows.net;Database=eshopdb;User Id=eshopsreadmin;Password=_Matilde11;Encrypt=true;TrustServerCertificate=false;Connection Timeout=30;"
CONNECTIONSTRINGS__IDENTITYCONNECTION="Server=eshopsre-sqlsrv.database.windows.net;Database=eshopdb;User Id=eshopsreadmin;Password=_Matilde11;Encrypt=true;TrustServerCertificate=false;Connection Timeout=30;"
```

### 🔄 Rebuild Docker Images

Run this to rebuild with updated configuration:
```powershell
.\build-and-push.ps1
```

### 🎯 Deployment Targets:

- **Azure App Service**: Use environment variables (Option 2)
- **Azure Container Apps**: Use environment variables (Option 3)
- **Azure Kubernetes Service**: Use ConfigMaps/Secrets
- **Local Docker**: Use AzureDirect environment (Option 1)

### 🔐 Security Notes:

⚠️  **IMPORTANT**: The `.env.deployment` file contains sensitive passwords. 
- Do NOT commit this file to source control
- Add it to `.gitignore`
- Use Azure Key Vault for production secrets

### 📞 Ready to Deploy!

Your application is now configured to connect to Azure SQL Database. Choose your deployment method and proceed with containerized deployment to Azure!
