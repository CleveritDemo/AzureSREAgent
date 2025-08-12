# Chaos Experiment Management Script (PowerShell)
# Usage: .\manage-chaos-experiments.ps1 [list|create|delete|status] [experiment-name]

param(
    [Parameter(Position=0)]
    [ValidateSet('list', 'status', 'create', 'delete', 'sync-state', 'validate', 'help')]
    [string]$Command = 'help',
    
    [Parameter(Position=1)]
    [string]$ExperimentName,
    
    [Parameter(Position=2)]
    [string]$TemplateType
)

$ResourceGroup = "eShopCleverRG"
$SubscriptionId = "5f62fee3-b00a-44d2-86e5-5cf130b28b5d"
$TerraformDir = ".\terraform-export-clean"

function Write-ColoredOutput {
    param(
        [string]$Message,
        [string]$Color = "White"
    )
    
    switch ($Color) {
        "Red" { Write-Host $Message -ForegroundColor Red }
        "Green" { Write-Host $Message -ForegroundColor Green }
        "Yellow" { Write-Host $Message -ForegroundColor Yellow }
        "Blue" { Write-Host $Message -ForegroundColor Blue }
        "Cyan" { Write-Host $Message -ForegroundColor Cyan }
        default { Write-Host $Message }
    }
}

function Show-Usage {
    Write-Host "Usage: .\manage-chaos-experiments.ps1 [command] [options]" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Commands:" -ForegroundColor Yellow
    Write-Host "  list                          List all chaos experiments"
    Write-Host "  status [experiment-name]      Show status of specific experiment"
    Write-Host "  create [template]             Create experiment from template"
    Write-Host "  delete [experiment-name]      Delete experiment (with confirmation)"
    Write-Host "  sync-state                    Synchronize Terraform state"
    Write-Host "  validate                      Validate all Terraform configurations"
    Write-Host ""
    Write-Host "Examples:" -ForegroundColor Yellow
    Write-Host "  .\manage-chaos-experiments.ps1 list"
    Write-Host "  .\manage-chaos-experiments.ps1 status eshoppodfailure"
    Write-Host "  .\manage-chaos-experiments.ps1 create pod-failure"
    Write-Host "  .\manage-chaos-experiments.ps1 delete my-experiment"
    Write-Host "  .\manage-chaos-experiments.ps1 sync-state"
}

function Test-Prerequisites {
    Write-ColoredOutput "Checking prerequisites..." "Blue"
    
    # Check if Azure CLI is installed
    try {
        $null = az --version
    } catch {
        Write-ColoredOutput "Error: Azure CLI is not installed" "Red"
        exit 1
    }
    
    # Check if logged in to Azure
    try {
        $null = az account show 2>$null
    } catch {
        Write-ColoredOutput "Error: Not logged in to Azure. Run 'az login' first" "Red"
        exit 1
    }
    
    # Check if Terraform is installed
    try {
        $null = terraform version
    } catch {
        Write-ColoredOutput "Error: Terraform is not installed" "Red"
        exit 1
    }
    
    # Check if kubectl is installed
    try {
        $null = kubectl version --client
    } catch {
        Write-ColoredOutput "Error: kubectl is not installed" "Red"
        exit 1
    }
    
    Write-ColoredOutput "✓ All prerequisites met" "Green"
}

function Get-ChaosExperiments {
    Write-ColoredOutput "Listing all chaos experiments..." "Blue"
    
    # List from Azure
    Write-Host ""
    Write-ColoredOutput "Azure Chaos Studio Experiments:" "Yellow"
    try {
        $azureExperiments = az rest --method GET `
            --url "https://management.azure.com/subscriptions/$SubscriptionId/resourceGroups/$ResourceGroup/providers/Microsoft.Chaos/experiments?api-version=2024-01-01" `
            --query "value[].{Name:name,Location:location,Status:properties.provisioningState}" `
            --output table 2>$null
        
        if ($azureExperiments) {
            Write-Host $azureExperiments
        } else {
            Write-Host "No experiments found in Azure"
        }
    } catch {
        Write-Host "Error retrieving experiments from Azure"
    }
    
    # List from Terraform state
    Write-Host ""
    Write-ColoredOutput "Terraform State Experiments:" "Yellow"
    if (Test-Path $TerraformDir) {
        Push-Location $TerraformDir
        try {
            terraform init -backend=true | Out-Null
            $stateList = terraform state list | Where-Object { $_ -match "azurerm_chaos_studio_experiment" }
            if ($stateList) {
                $stateList | ForEach-Object { $_ -replace "azurerm_chaos_studio_experiment\.", "" }
            } else {
                Write-Host "No experiments found in Terraform state"
            }
        } catch {
            Write-Host "Error reading Terraform state"
        } finally {
            Pop-Location
        }
    } else {
        Write-Host "Terraform directory not found"
    }
    
    # List Terraform files
    Write-Host ""
    Write-ColoredOutput "Terraform Configuration Files:" "Yellow"
    $configFiles = Get-ChildItem -Path $TerraformDir -Name "chaos-experiment-*.tf" -ErrorAction SilentlyContinue
    if ($configFiles) {
        $configFiles | ForEach-Object { 
            $_ -replace "chaos-experiment-", "" -replace "\.tf$", ""
        }
    } else {
        Write-Host "No experiment configuration files found"
    }
}

function Get-ExperimentStatus {
    param([string]$Name)
    
    if (-not $Name) {
        Write-ColoredOutput "Error: Experiment name required" "Red"
        exit 1
    }
    
    Write-ColoredOutput "Showing status for experiment: $Name" "Blue"
    
    # Get experiment details from Azure
    try {
        $experimentDetails = az rest --method GET `
            --url "https://management.azure.com/subscriptions/$SubscriptionId/resourceGroups/$ResourceGroup/providers/Microsoft.Chaos/experiments/$Name?api-version=2024-01-01" `
            2>$null | ConvertFrom-Json
        
        if ($experimentDetails) {
            Write-Host ""
            Write-ColoredOutput "✓ Experiment found in Azure" "Green"
            Write-Host "Name: $($experimentDetails.name)"
            Write-Host "Status: $($experimentDetails.properties.provisioningState)"
            Write-Host "Location: $($experimentDetails.location)"
            Write-Host "Created: $($experimentDetails.systemData.createdAt)"
            Write-Host "Last Modified: $($experimentDetails.systemData.lastModifiedAt)"
            
            # Get experiment executions
            Write-Host ""
            Write-ColoredOutput "Recent Executions:" "Yellow"
            try {
                $executions = az rest --method GET `
                    --url "https://management.azure.com/subscriptions/$SubscriptionId/resourceGroups/$ResourceGroup/providers/Microsoft.Chaos/experiments/$Name/executions?api-version=2024-01-01" `
                    --query "value[0:5].{Status:properties.status,Started:properties.startedAt,Stopped:properties.stoppedAt}" `
                    --output table 2>$null
                
                if ($executions) {
                    Write-Host $executions
                } else {
                    Write-Host "No executions found"
                }
            } catch {
                Write-Host "Error retrieving executions"
            }
        } else {
            Write-ColoredOutput "✗ Experiment not found in Azure" "Red"
        }
    } catch {
        Write-ColoredOutput "✗ Experiment not found in Azure" "Red"
    }
    
    # Check Terraform state
    if (Test-Path $TerraformDir) {
        Push-Location $TerraformDir
        try {
            terraform init -backend=true | Out-Null
            $stateShow = terraform state show "azurerm_chaos_studio_experiment.$Name" 2>$null
            if ($stateShow) {
                Write-Host ""
                Write-ColoredOutput "✓ Experiment found in Terraform state" "Green"
                $stateShow | Select-Object -First 20 | Write-Host
            } else {
                Write-Host ""
                Write-ColoredOutput "✗ Experiment not found in Terraform state" "Red"
            }
        } catch {
            Write-Host ""
            Write-ColoredOutput "✗ Experiment not found in Terraform state" "Red"
        } finally {
            Pop-Location
        }
    }
    
    # Check for configuration file
    $configFile = Join-Path $TerraformDir "chaos-experiment-$Name.tf"
    if (Test-Path $configFile) {
        Write-Host ""
        Write-ColoredOutput "✓ Configuration file exists: chaos-experiment-$Name.tf" "Green"
    } else {
        Write-Host ""
        Write-ColoredOutput "✗ Configuration file not found" "Red"
    }
}

function New-ExperimentTemplate {
    param([string]$TemplateType)
    
    if (-not $TemplateType) {
        Write-ColoredOutput "Error: Template type required" "Red"
        Write-Host "Available templates: pod-failure, cpu-stress, memory-stress, network-delay"
        exit 1
    }
    
    Write-ColoredOutput "Creating experiment template: $TemplateType" "Blue"
    
    # Generate a sample experiment name
    $experimentName = "sample-$TemplateType-$(Get-Date -Format 'yyyyMMddHHmmss')"
    
    Write-Host ""
    Write-Host "Use the GitHub Actions workflow to create the experiment:"
    Write-Host ""
    Write-Host "1. Go to: https://github.com/CleveritDemo/AzureSREAgent/actions/workflows/provision-chaos-experiment.yml"
    Write-Host "2. Click 'Run workflow'"
    Write-Host "3. Fill in the parameters:"
    Write-Host "   - Experiment name: $experimentName"
    Write-Host "   - Experiment type: $TemplateType"
    Write-Host "   - Target namespace: eshop"
    Write-Host "   - Target labels: {`"app`": `"eshop-webmvc`"}"
    Write-Host "   - Duration: 5 minutes"
    Write-Host "   - Action duration: 60s"
    Write-Host "4. Set 'dry_run' to true for testing"
    Write-Host ""
    Write-Host "Or use the GitHub CLI:"
    Write-Host "gh workflow run provision-chaos-experiment.yml \"
    Write-Host "  --field experiment_name=`"$experimentName`" \"
    Write-Host "  --field experiment_type=`"$TemplateType`" \"
    Write-Host "  --field target_namespace=`"eshop`" \"
    Write-Host "  --field target_labels='{`"app`": `"eshop-webmvc`"}' \"
    Write-Host "  --field duration_minutes=`"5`" \"
    Write-Host "  --field action_duration=`"60s`" \"
    Write-Host "  --field dry_run=true"
}

function Remove-Experiment {
    param([string]$Name)
    
    if (-not $Name) {
        Write-ColoredOutput "Error: Experiment name required" "Red"
        exit 1
    }
    
    Write-ColoredOutput "⚠️  This will delete the chaos experiment: $Name" "Yellow"
    Write-Host "This action will:"
    Write-Host "1. Remove the experiment from Azure Chaos Studio"
    Write-Host "2. Remove the resource from Terraform state"
    Write-Host "3. Delete the Terraform configuration file"
    Write-Host ""
    
    $response = Read-Host "Are you sure you want to continue? (yes/no)"
    
    if ($response -ne "yes") {
        Write-Host "Operation cancelled"
        exit 0
    }
    
    Write-ColoredOutput "Deleting experiment: $Name" "Blue"
    
    # Delete from Terraform
    if (Test-Path $TerraformDir) {
        Push-Location $TerraformDir
        try {
            terraform init -backend=true | Out-Null
            
            # Remove from state
            $stateExists = terraform state show "azurerm_chaos_studio_experiment.$Name" 2>$null
            if ($stateExists) {
                Write-Host "Removing from Terraform state..."
                terraform destroy -target="azurerm_chaos_studio_experiment.$Name" -auto-approve
            }
            
            # Remove configuration file
            $configFile = "chaos-experiment-$Name.tf"
            if (Test-Path $configFile) {
                Write-Host "Removing configuration file..."
                Remove-Item $configFile -Force
            }
        } catch {
            Write-ColoredOutput "Error during deletion: $_" "Red"
        } finally {
            Pop-Location
        }
    }
    
    Write-ColoredOutput "✓ Experiment deleted successfully" "Green"
}

function Sync-TerraformState {
    Write-ColoredOutput "Synchronizing Terraform state..." "Blue"
    
    if (-not (Test-Path $TerraformDir)) {
        Write-ColoredOutput "Error: Terraform directory not found" "Red"
        exit 1
    }
    
    Push-Location $TerraformDir
    try {
        # Initialize and refresh state
        Write-Host "Initializing Terraform..."
        terraform init -upgrade
        
        Write-Host "Refreshing state..."
        terraform refresh
        
        Write-Host "Validating configuration..."
        terraform validate
        
        Write-Host "Planning changes..."
        terraform plan -detailed-exitcode | Out-Null
        $planExitCode = $LASTEXITCODE
        
        switch ($planExitCode) {
            0 {
                Write-ColoredOutput "✓ No changes needed - state is in sync" "Green"
            }
            1 {
                Write-ColoredOutput "✗ Terraform plan failed" "Red"
                exit 1
            }
            2 {
                Write-ColoredOutput "⚠️  Changes detected - run 'terraform apply' to sync" "Yellow"
            }
        }
    } catch {
        Write-ColoredOutput "Error during state sync: $_" "Red"
    } finally {
        Pop-Location
    }
}

function Test-Configurations {
    Write-ColoredOutput "Validating all Terraform configurations..." "Blue"
    
    if (-not (Test-Path $TerraformDir)) {
        Write-ColoredOutput "Error: Terraform directory not found" "Red"
        exit 1
    }
    
    Push-Location $TerraformDir
    try {
        # Initialize
        terraform init -backend=true | Out-Null
        
        # Validate
        $validation = terraform validate
        if ($LASTEXITCODE -eq 0) {
            Write-ColoredOutput "✓ All configurations are valid" "Green"
        } else {
            Write-ColoredOutput "✗ Configuration validation failed" "Red"
            Write-Host $validation
            exit 1
        }
        
        # Check for syntax errors in individual files
        Write-Host ""
        Write-ColoredOutput "Checking individual experiment files:" "Yellow"
        $experimentFiles = Get-ChildItem -Name "chaos-experiment-*.tf" -ErrorAction SilentlyContinue
        foreach ($file in $experimentFiles) {
            Write-Host -NoNewline "Checking $file... "
            try {
                $validateResult = terraform validate -json | ConvertFrom-Json
                if ($validateResult.valid) {
                    Write-ColoredOutput "✓" "Green"
                } else {
                    Write-ColoredOutput "✗" "Red"
                }
            } catch {
                Write-ColoredOutput "✗" "Red"
            }
        }
    } catch {
        Write-ColoredOutput "Error during validation: $_" "Red"
    } finally {
        Pop-Location
    }
}

# Main script logic
switch ($Command) {
    "list" {
        Test-Prerequisites
        Get-ChaosExperiments
    }
    "status" {
        Test-Prerequisites
        Get-ExperimentStatus -Name $ExperimentName
    }
    "create" {
        New-ExperimentTemplate -TemplateType $ExperimentName
    }
    "delete" {
        Test-Prerequisites
        Remove-Experiment -Name $ExperimentName
    }
    "sync-state" {
        Test-Prerequisites
        Sync-TerraformState
    }
    "validate" {
        Test-Prerequisites
        Test-Configurations
    }
    "help" {
        Show-Usage
    }
    default {
        Write-ColoredOutput "Error: Unknown command '$Command'" "Red"
        Write-Host ""
        Show-Usage
        exit 1
    }
}
