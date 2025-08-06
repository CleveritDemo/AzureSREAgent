# Advanced Terraform State Analysis Tool
# This script provides detailed analysis of your Terraform state and Azure resources

param(
    [Parameter(Mandatory=$false)]
    [ValidateSet("analyze", "compare", "export", "health")]
    [string]$Action = "analyze",
    
    [Parameter(Mandatory=$false)]
    [string]$OutputFile = "state-analysis-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"
)

Write-Host "🔬 Advanced Terraform State Analysis Tool" -ForegroundColor Green
Write-Host "Action: $Action" -ForegroundColor Yellow

# Configuration
$resourceGroup = "eShopCleverRG"
$storageAccount = "eshopterraformstate8636"
$subscriptionId = "5f62fee3-b00a-44d2-86e5-5cf130b28b5d"

# Change to terraform directory
if (Test-Path "terraform-export-clean") {
    Set-Location "terraform-export-clean"
} else {
    Write-Host "❌ terraform-export-clean directory not found!" -ForegroundColor Red
    exit 1
}

# Initialize result object
$analysisResult = @{
    Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Action = $Action
    ResourceGroup = $resourceGroup
    StorageAccount = $storageAccount
    SubscriptionId = $subscriptionId
    TerraformResources = @()
    AzureResources = @()
    StateAnalysis = @{}
    HealthCheck = @{}
}

switch ($Action) {
    "analyze" {
        Write-Host "`n📊 Performing State Analysis..." -ForegroundColor Cyan
        
        # Get Terraform state resources with details
        Write-Host "Getting Terraform state resources..." -ForegroundColor Gray
        $terraformList = terraform state list
        
        foreach ($resource in $terraformList) {
            Write-Host "  Analyzing: $resource" -ForegroundColor Gray
            try {
                $stateShow = terraform state show $resource
                
                # Parse key attributes
                $resourceInfo = @{
                    Name = $resource
                    Type = ($resource -split '\.')[0]
                    Instance = ($resource -split '\.')[1]
                    Attributes = @{}
                }
                
                # Extract key attributes
                foreach ($line in $stateShow) {
                    if ($line -match '^\s*(\w+)\s*=\s*"?([^"]*)"?') {
                        $key = $matches[1]
                        $value = $matches[2]
                        
                        # Focus on important attributes
                        if ($key -in @('id', 'name', 'location', 'resource_group_name', 'sku', 'tier')) {
                            $resourceInfo.Attributes[$key] = $value
                        }
                    }
                }
                
                $analysisResult.TerraformResources += $resourceInfo
            } catch {
                Write-Host "  ❌ Error analyzing $resource`: $($_.Exception.Message)" -ForegroundColor Red
            }
        }
        
        # Get Azure resources
        Write-Host "`nGetting Azure resources..." -ForegroundColor Gray
        try {
            $azureResourcesJson = az resource list --resource-group $resourceGroup --output json
            $azureResourcesData = $azureResourcesJson | ConvertFrom-Json
            
            foreach ($azResource in $azureResourcesData) {
                $analysisResult.AzureResources += @{
                    Name = $azResource.name
                    Type = $azResource.type
                    Id = $azResource.id
                    Location = $azResource.location
                    Sku = $azResource.sku
                    Kind = $azResource.kind
                }
            }
        } catch {
            Write-Host "❌ Error getting Azure resources: $($_.Exception.Message)" -ForegroundColor Red
        }
        
        # Perform cross-analysis
        $analysisResult.StateAnalysis = @{
            TotalTerraformResources = $analysisResult.TerraformResources.Count
            TotalAzureResources = $analysisResult.AzureResources.Count
            Matches = @()
            Orphaned = @()
            Missing = @()
        }
        
        Write-Host "`n🔄 Cross-referencing resources..." -ForegroundColor Cyan
        
        # Check for matches
        foreach ($tfResource in $analysisResult.TerraformResources) {
            $resourceId = $tfResource.Attributes.id
            $matchingAzResource = $analysisResult.AzureResources | Where-Object { $_.Id -eq $resourceId }
            
            if ($matchingAzResource) {
                $analysisResult.StateAnalysis.Matches += @{
                    TerraformResource = $tfResource.Name
                    AzureResource = $matchingAzResource.Name
                    ResourceId = $resourceId
                    Status = "MATCHED"
                }
                Write-Host "  ✅ $($tfResource.Name) → $($matchingAzResource.Name)" -ForegroundColor Green
            } else {
                $analysisResult.StateAnalysis.Missing += @{
                    TerraformResource = $tfResource.Name
                    ResourceId = $resourceId
                    Status = "MISSING_IN_AZURE"
                }
                Write-Host "  ❌ $($tfResource.Name) → NOT FOUND IN AZURE" -ForegroundColor Red
            }
        }
        
        # Check for orphaned resources
        foreach ($azResource in $analysisResult.AzureResources) {
            $isManaged = $analysisResult.TerraformResources | Where-Object { $_.Attributes.id -eq $azResource.Id }
            
            if (-not $isManaged) {
                $analysisResult.StateAnalysis.Orphaned += @{
                    AzureResource = $azResource.Name
                    ResourceId = $azResource.Id
                    Type = $azResource.Type
                    Status = "NOT_IN_TERRAFORM"
                }
                Write-Host "  ⚠️ $($azResource.Name) → NOT MANAGED BY TERRAFORM" -ForegroundColor Yellow
            }
        }
    }
    
    "compare" {
        Write-Host "`n🔄 Performing Resource Comparison..." -ForegroundColor Cyan
        
        # Get current Terraform plan
        Write-Host "Running terraform plan..." -ForegroundColor Gray
        $planOutput = terraform plan -detailed-exitcode 2>&1
        
        $analysisResult.StateAnalysis.PlanStatus = @{
            ExitCode = $LASTEXITCODE
            HasChanges = $LASTEXITCODE -eq 2
            Output = $planOutput -join "`n"
        }
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✅ No changes detected - state is in sync" -ForegroundColor Green
        } elseif ($LASTEXITCODE -eq 2) {
            Write-Host "⚠️ Changes detected - state may be out of sync" -ForegroundColor Yellow
        } else {
            Write-Host "❌ Plan failed - check configuration" -ForegroundColor Red
        }
    }
    
    "export" {
        Write-Host "`n📤 Exporting State Data..." -ForegroundColor Cyan
        
        # Export current state
        $stateFile = "terraform.tfstate.backup"
        terraform state pull > $stateFile
        
        if (Test-Path $stateFile) {
            Write-Host "✅ State exported to: $stateFile" -ForegroundColor Green
            $analysisResult.StateAnalysis.StateExport = @{
                File = $stateFile
                Size = (Get-Item $stateFile).Length
                Created = Get-Date
            }
        }
    }
    
    "health" {
        Write-Host "`n🏥 Performing Health Check..." -ForegroundColor Cyan
        
        # Check backend connectivity
        try {
            terraform init -backend=true
            $analysisResult.HealthCheck.BackendConnectivity = "OK"
            Write-Host "✅ Backend connectivity: OK" -ForegroundColor Green
        } catch {
            $analysisResult.HealthCheck.BackendConnectivity = "FAILED"
            Write-Host "❌ Backend connectivity: FAILED" -ForegroundColor Red
        }
        
        # Check state lock
        try {
            terraform state list > $null
            $analysisResult.HealthCheck.StateLock = "OK"
            Write-Host "✅ State lock: OK" -ForegroundColor Green
        } catch {
            $analysisResult.HealthCheck.StateLock = "FAILED"
            Write-Host "❌ State lock: FAILED" -ForegroundColor Red
        }
        
        # Check Azure authentication
        try {
            az account show > $null
            $analysisResult.HealthCheck.AzureAuth = "OK"
            Write-Host "✅ Azure authentication: OK" -ForegroundColor Green
        } catch {
            $analysisResult.HealthCheck.AzureAuth = "FAILED"
            Write-Host "❌ Azure authentication: FAILED" -ForegroundColor Red
        }
        
        # Check storage account access
        try {
            az storage blob list --account-name $storageAccount --container-name "tfstate" --auth-mode login > $null
            $analysisResult.HealthCheck.StorageAccess = "OK"
            Write-Host "✅ Storage account access: OK" -ForegroundColor Green
        } catch {
            $analysisResult.HealthCheck.StorageAccess = "FAILED"
            Write-Host "❌ Storage account access: FAILED" -ForegroundColor Red
        }
    }
}

# Output results
Write-Host "`n📊 Analysis Complete!" -ForegroundColor Green

if ($Action -eq "analyze") {
    Write-Host "`n📈 Summary:" -ForegroundColor Yellow
    Write-Host "  • Terraform Resources: $($analysisResult.StateAnalysis.TotalTerraformResources)"
    Write-Host "  • Azure Resources: $($analysisResult.StateAnalysis.TotalAzureResources)"
    Write-Host "  • Matched Resources: $($analysisResult.StateAnalysis.Matches.Count)"
    Write-Host "  • Missing in Azure: $($analysisResult.StateAnalysis.Missing.Count)"
    Write-Host "  • Orphaned in Azure: $($analysisResult.StateAnalysis.Orphaned.Count)"
}

# Save results to file
$analysisResult | ConvertTo-Json -Depth 10 | Out-File -FilePath "..\$OutputFile" -Encoding UTF8
Write-Host "`n💾 Results saved to: $OutputFile" -ForegroundColor Cyan

# Return to original directory
Set-Location ..

Write-Host "`n🔧 Usage Examples:" -ForegroundColor Cyan
Write-Host "  .\state-analysis.ps1 -Action analyze    # Full analysis"
Write-Host "  .\state-analysis.ps1 -Action compare    # Check for drift"
Write-Host "  .\state-analysis.ps1 -Action export     # Export state"
Write-Host "  .\state-analysis.ps1 -Action health     # Health check"
