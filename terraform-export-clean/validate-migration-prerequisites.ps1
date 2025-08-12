# Pre-Migration Validation Script
# This script validates prerequisites before running the cross-tenant migration

param(
    [Parameter(Mandatory=$true)]
    [string]$TargetTenantId,
    
    [Parameter(Mandatory=$true)]
    [string]$TargetSubscriptionId
)

Write-Host "🔍 Pre-Migration Validation Tool" -ForegroundColor Green
Write-Host "================================" -ForegroundColor Green
Write-Host ""

$validationResults = @()

# Function to add validation result
function Add-ValidationResult {
    param($Test, $Status, $Details)
    $validationResults += [PSCustomObject]@{
        Test = $Test
        Status = $Status
        Details = $Details
    }
}

# Test 1: Check if Azure CLI is installed and authenticated
Write-Host "🔧 Testing Azure CLI..." -ForegroundColor Blue
try {
    $currentAccount = az account show 2>$null | ConvertFrom-Json
    if ($currentAccount) {
        Add-ValidationResult "Azure CLI Authentication" "✅ PASS" "Authenticated as: $($currentAccount.user.name)"
    } else {
        Add-ValidationResult "Azure CLI Authentication" "❌ FAIL" "Not authenticated. Run 'az login' first."
    }
} catch {
    Add-ValidationResult "Azure CLI" "❌ FAIL" "Azure CLI not installed or not in PATH"
}

# Test 2: Check if Terraform is installed
Write-Host "🏗️ Testing Terraform..." -ForegroundColor Blue
try {
    $tfVersion = terraform version 2>$null
    if ($tfVersion) {
        Add-ValidationResult "Terraform Installation" "✅ PASS" "Terraform is installed"
    } else {
        Add-ValidationResult "Terraform Installation" "❌ FAIL" "Terraform not found in PATH"
    }
} catch {
    Add-ValidationResult "Terraform Installation" "❌ FAIL" "Terraform not installed"
}

# Test 3: Check access to target tenant
Write-Host "🏢 Testing target tenant access..." -ForegroundColor Blue
try {
    # Try to login to target tenant (non-interactive check)
    $tenants = az account tenant list 2>$null | ConvertFrom-Json
    $targetTenant = $tenants | Where-Object { $_.tenantId -eq $TargetTenantId }
    
    if ($targetTenant) {
        Add-ValidationResult "Target Tenant Access" "✅ PASS" "Target tenant accessible: $($targetTenant.displayName)"
    } else {
        Add-ValidationResult "Target Tenant Access" "❌ FAIL" "Target tenant $TargetTenantId not accessible"
    }
} catch {
    Add-ValidationResult "Target Tenant Access" "❌ FAIL" "Could not verify tenant access"
}

# Test 4: Check if we can access target subscription
Write-Host "📊 Testing target subscription access..." -ForegroundColor Blue
try {
    # Switch to target tenant first
    az login --tenant $TargetTenantId --allow-no-subscriptions 2>$null >$null
    $subscriptions = az account list 2>$null | ConvertFrom-Json
    $targetSub = $subscriptions | Where-Object { $_.id -eq $TargetSubscriptionId }
    
    if ($targetSub) {
        Add-ValidationResult "Target Subscription Access" "✅ PASS" "Target subscription accessible: $($targetSub.name)"
    } else {
        Add-ValidationResult "Target Subscription Access" "❌ FAIL" "Target subscription $TargetSubscriptionId not accessible"
    }
} catch {
    Add-ValidationResult "Target Subscription Access" "❌ FAIL" "Could not verify subscription access"
}

# Test 5: Check permissions in target subscription
Write-Host "🔐 Testing target subscription permissions..." -ForegroundColor Blue
try {
    az account set --subscription $TargetSubscriptionId 2>$null
    # Try to list resource groups to test permissions
    $rgs = az group list 2>$null | ConvertFrom-Json
    if ($rgs) {
        Add-ValidationResult "Target Subscription Permissions" "✅ PASS" "Can list resource groups in target subscription"
    } else {
        Add-ValidationResult "Target Subscription Permissions" "❌ FAIL" "Cannot list resource groups - insufficient permissions"
    }
} catch {
    Add-ValidationResult "Target Subscription Permissions" "❌ FAIL" "Could not verify permissions"
}

# Test 6: Check if current Terraform state exists and is accessible
Write-Host "🗄️ Testing current Terraform state..." -ForegroundColor Blue
try {
    if (Test-Path ".terraform") {
        $stateList = terraform state list 2>$null
        if ($stateList) {
            $resourceCount = ($stateList | Measure-Object).Count
            Add-ValidationResult "Current Terraform State" "✅ PASS" "Current state has $resourceCount resources"
        } else {
            Add-ValidationResult "Current Terraform State" "⚠️ WARN" "Terraform initialized but no resources in state"
        }
    } else {
        Add-ValidationResult "Current Terraform State" "⚠️ WARN" "Terraform not initialized. Run 'terraform init' first."
    }
} catch {
    Add-ValidationResult "Current Terraform State" "❌ FAIL" "Could not access Terraform state"
}

# Test 7: Check if required files exist
Write-Host "📁 Testing required files..." -ForegroundColor Blue
$requiredFiles = @("main.tf", "variables.tf", "resources.tf", "backend.tf")
$missingFiles = @()

foreach ($file in $requiredFiles) {
    if (-not (Test-Path $file)) {
        $missingFiles += $file
    }
}

if ($missingFiles.Count -eq 0) {
    Add-ValidationResult "Required Files" "✅ PASS" "All required Terraform files present"
} else {
    Add-ValidationResult "Required Files" "❌ FAIL" "Missing files: $($missingFiles -join ', ')"
}

# Test 8: Check available disk space for backups
Write-Host "💾 Testing disk space..." -ForegroundColor Blue
try {
    $drive = Get-WmiObject -Class Win32_LogicalDisk | Where-Object { $_.DeviceID -eq "C:" }
    $freeSpaceGB = [math]::Round($drive.FreeSpace / 1GB, 2)
    
    if ($freeSpaceGB -gt 1) {
        Add-ValidationResult "Disk Space" "✅ PASS" "$freeSpaceGB GB available for migration backups"
    } else {
        Add-ValidationResult "Disk Space" "⚠️ WARN" "Low disk space: $freeSpaceGB GB (recommend >1GB for backups)"
    }
} catch {
    Add-ValidationResult "Disk Space" "⚠️ WARN" "Could not check disk space"
}

# Display results
Write-Host ""
Write-Host "📋 Validation Results:" -ForegroundColor Blue
Write-Host "=====================" -ForegroundColor Blue
Write-Host ""

$passCount = 0
$failCount = 0
$warnCount = 0

foreach ($result in $validationResults) {
    Write-Host "$($result.Test): $($result.Status)" -ForegroundColor White
    Write-Host "   $($result.Details)" -ForegroundColor Gray
    Write-Host ""
    
    if ($result.Status -like "*PASS*") { $passCount++ }
    elseif ($result.Status -like "*FAIL*") { $failCount++ }
    elseif ($result.Status -like "*WARN*") { $warnCount++ }
}

Write-Host "📊 Summary:" -ForegroundColor Blue
Write-Host "   ✅ Passed: $passCount" -ForegroundColor Green
Write-Host "   ❌ Failed: $failCount" -ForegroundColor Red
Write-Host "   ⚠️ Warnings: $warnCount" -ForegroundColor Yellow
Write-Host ""

if ($failCount -eq 0) {
    Write-Host "🎉 Pre-migration validation completed successfully!" -ForegroundColor Green
    Write-Host "You can proceed with the migration using:" -ForegroundColor Green
    Write-Host ".\migrate-to-new-tenant.ps1 -TargetTenantId '$TargetTenantId' -TargetSubscriptionId '$TargetSubscriptionId'" -ForegroundColor Yellow
} else {
    Write-Host "❌ Pre-migration validation failed. Please address the issues above before proceeding." -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "💡 Migration Tips:" -ForegroundColor Blue
Write-Host "   1. Start with -PlanOnly to preview changes" -ForegroundColor Gray
Write-Host "   2. Use -CreateStateBackend if you need a new Terraform state backend" -ForegroundColor Gray
Write-Host "   3. Ensure you have the SQL admin password ready" -ForegroundColor Gray
Write-Host "   4. Consider running during low-usage hours" -ForegroundColor Gray
