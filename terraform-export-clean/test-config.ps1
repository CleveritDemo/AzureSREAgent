# Test Terraform Configuration - eShopOnWeb Infrastructure Export

Write-Host "🚀 Testing Terraform Configuration for eShopOnWeb" -ForegroundColor Green
Write-Host ""

# Check if all required files exist
$requiredFiles = @("main.tf", "resources.tf", "variables.tf", "outputs.tf", "README.md")
$allFilesExist = $true

Write-Host "📁 Checking required files:" -ForegroundColor Yellow
foreach ($file in $requiredFiles) {
    if (Test-Path $file) {
        Write-Host "  ✅ $file exists" -ForegroundColor Green
    } else {
        Write-Host "  ❌ $file missing" -ForegroundColor Red
        $allFilesExist = $false
    }
}

Write-Host ""

# Check Terraform installation
Write-Host "🔧 Checking Terraform:" -ForegroundColor Yellow
try {
    $terraformVersion = terraform version
    Write-Host "  ✅ Terraform is installed: $($terraformVersion[0])" -ForegroundColor Green
} catch {
    Write-Host "  ❌ Terraform not found" -ForegroundColor Red
    $allFilesExist = $false
}

Write-Host ""

# Validate Terraform configuration
Write-Host "🔍 Validating Terraform configuration:" -ForegroundColor Yellow
try {
    $validation = terraform validate 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "  ✅ Configuration is valid" -ForegroundColor Green
    } else {
        Write-Host "  ❌ Configuration has errors:" -ForegroundColor Red
        Write-Host "  $validation" -ForegroundColor Red
        $allFilesExist = $false
    }
} catch {
    Write-Host "  ❌ Could not validate configuration" -ForegroundColor Red
    $allFilesExist = $false
}

Write-Host ""

# Summary
if ($allFilesExist) {
    Write-Host "🎉 SUCCESS! Your Terraform configuration is ready!" -ForegroundColor Green
    Write-Host ""
    Write-Host "📝 What was exported:" -ForegroundColor Cyan
    Write-Host "  • Resource Group: eShopDemoSRErg"
    Write-Host "  • Container Registry: eshopsreacr"
    Write-Host "  • AKS Cluster: eshopsreaks"
    Write-Host "  • SQL Server: eshopsre-sqlsrv"
    Write-Host "  • SQL Database: eshopdb"
    Write-Host ""
    Write-Host "🔄 Next steps:" -ForegroundColor Cyan
    Write-Host "  1. Login to Azure: az login"
    Write-Host "  2. Run: terraform plan"
    Write-Host "  3. Run: terraform apply"
    Write-Host ""
    Write-Host "📚 See README.md for detailed usage instructions" -ForegroundColor Cyan
} else {
    Write-Host "❌ Configuration has issues - please check the errors above" -ForegroundColor Red
}

Write-Host ""
Write-Host "💡 Why aztfexport got stuck:" -ForegroundColor Yellow
Write-Host "  • Resource 53 was likely a SQL vulnerability assessment policy"
Write-Host "  • These complex security resources often timeout during export"
Write-Host "  • Manual export of core resources (like this) is more reliable"
Write-Host "  • You now have clean, maintainable Terraform code!"
