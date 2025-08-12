# Test script for Terraform Azure authentication (PowerShell)
# Run this locally to test if your Terraform configuration works

Write-Host "🔧 Testing Terraform Azure Authentication Configuration..." -ForegroundColor Cyan

# Check if Azure CLI is logged in
Write-Host "Checking Azure CLI authentication..."
try {
    $account = az account show | ConvertFrom-Json
    Write-Host "✅ Azure CLI is authenticated" -ForegroundColor Green
    Write-Host "Subscription: $($account.name) ($($account.id))"
    Write-Host "Tenant: $($account.tenantId)"
} catch {
    Write-Host "❌ Azure CLI is not authenticated. Please run 'az login'" -ForegroundColor Red
    exit 1
}

# Test Terraform configuration
Write-Host ""
Write-Host "Testing Terraform configuration..."
Push-Location terraform-export-clean

try {
    # Initialize Terraform
    Write-Host "Initializing Terraform..."
    $initResult = terraform init -backend=true
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Terraform init successful" -ForegroundColor Green
    } else {
        Write-Host "❌ Terraform init failed" -ForegroundColor Red
        Write-Host $initResult
        exit 1
    }

    # Validate configuration
    Write-Host "Validating Terraform configuration..."
    $validateResult = terraform validate
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Terraform validation successful" -ForegroundColor Green
    } else {
        Write-Host "❌ Terraform validation failed" -ForegroundColor Red
        Write-Host $validateResult
        exit 1
    }

    # Plan (dry run)
    Write-Host "Running Terraform plan (dry run)..."
    terraform plan -out test.tfplan
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Terraform plan successful" -ForegroundColor Green
        
        # Show plan summary
        Write-Host ""
        Write-Host "Plan summary:"
        try {
            $planJson = terraform show -json test.tfplan | ConvertFrom-Json
            $chaosResources = $planJson.planned_values.root_module.resources | Where-Object { $_.type -like "azurerm_chaos*" }
            if ($chaosResources) {
                foreach ($resource in $chaosResources) {
                    Write-Host "  - $($resource.type).$($resource.name)"
                }
            } else {
                Write-Host "  - No chaos experiment resources found in plan"
            }
        } catch {
            Write-Host "  - Could not parse plan JSON, but plan was successful"
        }
        
        # Cleanup
        Remove-Item test.tfplan -ErrorAction SilentlyContinue
    } else {
        Write-Host "❌ Terraform plan failed" -ForegroundColor Red
        exit 1
    }
} finally {
    Pop-Location
}

Write-Host ""
Write-Host "🎉 All tests passed! Terraform configuration is ready for GitHub Actions." -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "1. Ensure these secrets are set in your GitHub repository:"
Write-Host "   - AZURE_CLIENT_ID"
Write-Host "   - AZURE_TENANT_ID"
Write-Host "   - AZURE_SUBSCRIPTION_ID"
Write-Host "2. Run the GitHub Actions workflow to provision chaos experiments"
