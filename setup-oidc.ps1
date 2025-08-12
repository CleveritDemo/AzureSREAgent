# 🚀 OIDC Federation Setup Script
# Run this script to configure OIDC federation for your Service Principal

Write-Host "🔐 Setting up OIDC Federation for GitHub Actions" -ForegroundColor Green
Write-Host "=================================================" -ForegroundColor Green
Write-Host ""

# Service Principal details
$servicePrincipalAppId = "2e5ce55e-70e6-44b8-94b5-14f174babccd"
$repoName = "CleveritDemo/AzureSREAgent"

Write-Host "📋 Configuration Details:" -ForegroundColor Yellow
Write-Host "   Service Principal App ID: $servicePrincipalAppId"
Write-Host "   GitHub Repository: $repoName"
Write-Host "   OIDC Issuer: https://token.actions.githubusercontent.com"
Write-Host ""

Write-Host "🎯 AZURE ADMIN: Please run these commands:" -ForegroundColor Cyan
Write-Host ""

# Command 1: Main branch federation
Write-Host "# 1. Create OIDC federation for main branch:" -ForegroundColor Yellow
$mainBranchCommand = @"
az ad app federated-credential create \
  --id "$servicePrincipalAppId" \
  --parameters '{
    "name": "github-actions-main-branch",
    "issuer": "https://token.actions.githubusercontent.com",
    "subject": "repo:$repoName:ref:refs/heads/main",
    "description": "GitHub Actions OIDC for main branch",
    "audiences": ["api://AzureADTokenExchange"]
  }'
"@
Write-Host $mainBranchCommand -ForegroundColor Cyan
Write-Host ""

# Command 2: Pull request federation
Write-Host "# 2. Create OIDC federation for pull requests:" -ForegroundColor Yellow
$pullRequestCommand = @"
az ad app federated-credential create \
  --id "$servicePrincipalAppId" \
  --parameters '{
    "name": "github-actions-pull-requests", 
    "issuer": "https://token.actions.githubusercontent.com",
    "subject": "repo:$repoName:pull_request",
    "description": "GitHub Actions OIDC for pull requests",
    "audiences": ["api://AzureADTokenExchange"]
  }'
"@
Write-Host $pullRequestCommand -ForegroundColor Cyan
Write-Host ""

# Command 3: Environment-specific federation (optional)
Write-Host "# 3. Create OIDC federation for production environment (optional):" -ForegroundColor Yellow
$environmentCommand = @"
az ad app federated-credential create \
  --id "$servicePrincipalAppId" \
  --parameters '{
    "name": "github-actions-production-env",
    "issuer": "https://token.actions.githubusercontent.com", 
    "subject": "repo:$repoName:environment:production",
    "description": "GitHub Actions OIDC for production environment",
    "audiences": ["api://AzureADTokenExchange"]
  }'
"@
Write-Host $environmentCommand -ForegroundColor Cyan
Write-Host ""

# Verification command
Write-Host "# 4. Verify the federated credentials:" -ForegroundColor Yellow
$verifyCommand = "az ad app federated-credential list --id `"$servicePrincipalAppId`" --output table"
Write-Host $verifyCommand -ForegroundColor Cyan
Write-Host ""

Write-Host "✅ After running these commands:" -ForegroundColor Green
Write-Host "   1. Your GitHub Actions will authenticate using OIDC tokens"
Write-Host "   2. No passwords or client secrets needed!"
Write-Host "   3. Enhanced security with short-lived tokens"
Write-Host "   4. You can safely DELETE the AZURE_CLIENT_SECRET from GitHub"
Write-Host ""

Write-Host "🧪 Test your OIDC setup:" -ForegroundColor Yellow
Write-Host "   1. Go to: https://github.com/CleveritDemo/AzureSREAgent/actions"
Write-Host "   2. Run any workflow (e.g., 'Provision Chaos Experiment')"
Write-Host "   3. Check that authentication succeeds without client secret"
Write-Host ""

Write-Host "🗑️ GitHub Secrets Cleanup:" -ForegroundColor Red
Write-Host "   After successful OIDC testing, you can safely DELETE:"
Write-Host "   ❌ AZURE_CLIENT_SECRET (no longer needed!)"
Write-Host ""
Write-Host "   Keep these secrets:"
Write-Host "   ✅ AZURE_CLIENT_ID = $servicePrincipalAppId"
Write-Host "   ✅ AZURE_TENANT_ID = 1c8ef991-ec57-4212-b273-fb4e9ccd060d"
Write-Host "   ✅ AZURE_SUBSCRIPTION_ID = d7d7369b-a14f-43bc-a564-b4a077d170a9"
Write-Host ""

Write-Host "🎉 Your GitHub Actions will be more secure with OIDC!" -ForegroundColor Green
