# Helper Script to Find Subscriptions and Tenants
# Usage: .\find-subscriptions.ps1

Write-Host "🔍 Azure Subscription and Tenant Discovery" -ForegroundColor Green
Write-Host ""

# Function to display tenant information
function Show-TenantInfo {
    param($tenantId)
    
    Write-Host "🏢 Tenant: $tenantId" -ForegroundColor Yellow
    try {
        # Get tenant details
        $tenant = az rest --method get --url "https://graph.microsoft.com/v1.0/organization" --query "value[0]" | ConvertFrom-Json
        if ($tenant) {
            Write-Host "   Display Name: $($tenant.displayName)" -ForegroundColor Gray
            Write-Host "   Domain: $($tenant.verifiedDomains[0].name)" -ForegroundColor Gray
        }
    } catch {
        Write-Host "   (Could not fetch tenant details)" -ForegroundColor Gray
    }
}

# Check current authentication status
Write-Host "📋 Current Authentication Status:" -ForegroundColor Blue
try {
    $currentAccount = az account show | ConvertFrom-Json
    Write-Host "✅ Currently authenticated as: $($currentAccount.user.name)" -ForegroundColor Green
    Write-Host "   Current Subscription: $($currentAccount.name) ($($currentAccount.id))" -ForegroundColor Gray
    Write-Host "   Current Tenant: $($currentAccount.tenantId)" -ForegroundColor Gray
    Write-Host ""
} catch {
    Write-Host "❌ Not authenticated. Please run 'az login' first." -ForegroundColor Red
    exit 1
}

# List all available tenants
Write-Host "🏢 Available Tenants:" -ForegroundColor Blue
try {
    $tenants = az account tenant list | ConvertFrom-Json
    foreach ($tenant in $tenants) {
        Show-TenantInfo $tenant.tenantId
        Write-Host ""
    }
} catch {
    Write-Host "❌ Could not list tenants. You may need to run 'az login' again." -ForegroundColor Red
}

# List all subscriptions
Write-Host "📊 All Available Subscriptions:" -ForegroundColor Blue
try {
    $subscriptions = az account list | ConvertFrom-Json
    
    # Group subscriptions by tenant
    $subscriptionsByTenant = $subscriptions | Group-Object tenantId
    
    foreach ($tenantGroup in $subscriptionsByTenant) {
        Write-Host ""
        Write-Host "🏢 Tenant: $($tenantGroup.Name)" -ForegroundColor Yellow
        
        foreach ($sub in $tenantGroup.Group) {
            $isDefault = if ($sub.isDefault) { " (DEFAULT)" } else { "" }
            $state = if ($sub.state -eq "Enabled") { "✅" } else { "❌" }
            
            Write-Host "   $state $($sub.name)$isDefault" -ForegroundColor Green
            Write-Host "      Subscription ID: $($sub.id)" -ForegroundColor Gray
            Write-Host "      State: $($sub.state)" -ForegroundColor Gray
            Write-Host ""
        }
    }
} catch {
    Write-Host "❌ Could not list subscriptions." -ForegroundColor Red
}

Write-Host "🎯 Next Steps:" -ForegroundColor Blue
Write-Host "1. Choose your target tenant and subscription from the list above" -ForegroundColor White
Write-Host "2. Copy the Subscription ID and Tenant ID" -ForegroundColor White
Write-Host "3. Edit your .tfvars file with these values:" -ForegroundColor White
Write-Host ""
Write-Host "   subscription_id = `"YOUR_CHOSEN_SUBSCRIPTION_ID`"" -ForegroundColor Yellow
Write-Host "   tenant_id      = `"YOUR_CHOSEN_TENANT_ID`"" -ForegroundColor Yellow
Write-Host ""
Write-Host "4. To switch to a different tenant:" -ForegroundColor White
Write-Host "   az login --tenant YOUR_CHOSEN_TENANT_ID" -ForegroundColor Yellow
Write-Host ""
Write-Host "5. To switch to a different subscription:" -ForegroundColor White
Write-Host "   az account set --subscription YOUR_CHOSEN_SUBSCRIPTION_ID" -ForegroundColor Yellow
Write-Host ""
Write-Host "6. Deploy using:" -ForegroundColor White
Write-Host "   .\deploy-environment.ps1 -Environment custom -TfvarsFile `"your-custom.tfvars`"" -ForegroundColor Yellow
