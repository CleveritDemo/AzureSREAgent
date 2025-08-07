# Deploy Custom Domain for eShopOnWeb
# This script automates the complete custom domain deployment process

param(
    [Parameter(Mandatory=$true)]
    [string]$DomainName = "eshopclever.com",
    
    [Parameter(Mandatory=$false)]
    [string]$Environment = "production",
    
    [Parameter(Mandatory=$false)]
    [switch]$SkipDNSZone,
    
    [Parameter(Mandatory=$false)]
    [switch]$DryRun
)

# Set error action preference
$ErrorActionPreference = "Stop"

Write-Host "🚀 Starting Custom Domain Deployment for eShopOnWeb" -ForegroundColor Green
Write-Host "Domain: $DomainName" -ForegroundColor Cyan
Write-Host "Environment: $Environment" -ForegroundColor Cyan

# Function to check prerequisites
function Test-Prerequisites {
    Write-Host "🔍 Checking prerequisites..." -ForegroundColor Yellow
    
    # Check Azure CLI
    try {
        $azVersion = az version --output tsv 2>$null
        Write-Host "✅ Azure CLI is installed" -ForegroundColor Green
    } catch {
        Write-Error "❌ Azure CLI not found. Please install Azure CLI first."
    }
    
    # Check kubectl
    try {
        $kubectlVersion = kubectl version --client --short 2>$null
        Write-Host "✅ kubectl is installed" -ForegroundColor Green
    } catch {
        Write-Error "❌ kubectl not found. Please install kubectl first."
    }
    
    # Check Azure login
    try {
        $account = az account show --output json 2>$null | ConvertFrom-Json
        Write-Host "✅ Logged in to Azure as: $($account.user.name)" -ForegroundColor Green
    } catch {
        Write-Error "❌ Not logged in to Azure. Run 'az login' first."
    }
    
    # Check AKS connection
    try {
        $context = kubectl config current-context 2>$null
        Write-Host "✅ Connected to Kubernetes context: $context" -ForegroundColor Green
    } catch {
        Write-Error "❌ No Kubernetes context found. Make sure you're connected to your AKS cluster."
    }
}

# Function to deploy infrastructure
function Deploy-Infrastructure {
    Write-Host "🏗️ Deploying infrastructure with DNS zone..." -ForegroundColor Yellow
    
    if ($DryRun) {
        Write-Host "💡 DRY RUN: Would deploy infrastructure to $Environment environment" -ForegroundColor Magenta
        return
    }
    
    # Navigate to terraform directory
    Push-Location "terraform-export-clean"
    
    try {
        # Update tfvars file
        $tfvarsPath = "$Environment.tfvars"
        if (Test-Path $tfvarsPath) {
            Write-Host "📝 Updating $tfvarsPath with custom domain settings..." -ForegroundColor Yellow
            
            # Read current content
            $content = Get-Content $tfvarsPath -Raw
            
            # Update or add custom domain settings
            if ($content -match 'enable_custom_domain\s*=') {
                $content = $content -replace 'enable_custom_domain\s*=.*', "enable_custom_domain = true"
            } else {
                $content += "`n`n# Custom Domain Configuration`nenable_custom_domain = true"
            }
            
            if ($content -match 'custom_domain_name\s*=') {
                $content = $content -replace 'custom_domain_name\s*=.*', "custom_domain_name = `"$DomainName`""
            } else {
                $content += "`ncustom_domain_name = `"$DomainName`""
            }
            
            if ($content -match 'ingress_ip_address\s*=') {
                $content = $content -replace 'ingress_ip_address\s*=.*', 'ingress_ip_address = "0.0.0.0"  # Will be updated after ingress deployment'
            } else {
                $content += "`ningress_ip_address = `"0.0.0.0`"  # Will be updated after ingress deployment"
            }
            
            Set-Content $tfvarsPath -Value $content
            Write-Host "✅ Updated $tfvarsPath" -ForegroundColor Green
        } else {
            Write-Error "❌ Terraform variables file not found: $tfvarsPath"
        }
        
        # Deploy infrastructure
        Write-Host "🚀 Running terraform deployment..." -ForegroundColor Yellow
        & ".\deploy-environment.ps1" -Environment $Environment
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✅ Infrastructure deployed successfully" -ForegroundColor Green
        } else {
            Write-Error "❌ Infrastructure deployment failed"
        }
        
    } finally {
        Pop-Location
    }
}

# Function to set up ingress
function Deploy-IngressInfrastructure {
    Write-Host "🌐 Setting up NGINX Ingress and cert-manager..." -ForegroundColor Yellow
    
    if ($DryRun) {
        Write-Host "💡 DRY RUN: Would deploy ingress infrastructure" -ForegroundColor Magenta
        return
    }
    
    & ".\setup-custom-domain.ps1"
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Ingress infrastructure deployed successfully" -ForegroundColor Green
    } else {
        Write-Error "❌ Ingress infrastructure deployment failed"
    }
}

# Function to get ingress IP
function Get-IngressIP {
    Write-Host "🔍 Getting ingress external IP address..." -ForegroundColor Yellow
    
    $maxAttempts = 30
    $attempt = 0
    
    do {
        $attempt++
        Write-Host "⏳ Attempt $attempt of $maxAttempts - Waiting for external IP..." -ForegroundColor Yellow
        
        try {
            $ip = kubectl get svc -n ingress-nginx ingress-nginx-controller -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>$null
            
            if ($ip -and $ip -ne "null" -and $ip -ne "") {
                Write-Host "✅ Got ingress IP: $ip" -ForegroundColor Green
                return $ip
            }
        } catch {
            # Continue waiting
        }
        
        Start-Sleep -Seconds 10
        
    } while ($attempt -lt $maxAttempts)
    
    Write-Error "❌ Timeout waiting for ingress external IP"
}

# Function to update DNS records
function Update-DNSRecords {
    param([string]$IngressIP)
    
    Write-Host "📝 Updating DNS records with ingress IP: $IngressIP" -ForegroundColor Yellow
    
    if ($DryRun) {
        Write-Host "💡 DRY RUN: Would update DNS records with IP $IngressIP" -ForegroundColor Magenta
        return
    }
    
    Push-Location "terraform-export-clean"
    
    try {
        # Update tfvars file with actual ingress IP
        $tfvarsPath = "$Environment.tfvars"
        $content = Get-Content $tfvarsPath -Raw
        $content = $content -replace 'ingress_ip_address\s*=.*', "ingress_ip_address = `"$IngressIP`""
        Set-Content $tfvarsPath -Value $content
        
        # Re-run terraform to update DNS records
        Write-Host "🚀 Updating DNS records..." -ForegroundColor Yellow
        & ".\deploy-environment.ps1" -Environment $Environment
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✅ DNS records updated successfully" -ForegroundColor Green
        } else {
            Write-Error "❌ DNS records update failed"
        }
        
    } finally {
        Pop-Location
    }
}

# Function to deploy application ingress
function Deploy-ApplicationIngress {
    Write-Host "📱 Deploying application ingress configurations..." -ForegroundColor Yellow
    
    if ($DryRun) {
        Write-Host "💡 DRY RUN: Would deploy application ingress" -ForegroundColor Magenta
        return
    }
    
    # Deploy custom domain ingress
    if (Test-Path "k8s\ingress-custom-domain.yaml") {
        Write-Host "🚀 Deploying production ingress..." -ForegroundColor Yellow
        kubectl apply -f "k8s\ingress-custom-domain.yaml"
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✅ Production ingress deployed" -ForegroundColor Green
        } else {
            Write-Warning "⚠️ Production ingress deployment had issues"
        }
    }
    
    # Deploy staging ingress (optional)
    if (Test-Path "k8s\ingress-staging.yaml") {
        Write-Host "🚀 Deploying staging ingress..." -ForegroundColor Yellow
        kubectl apply -f "k8s\ingress-staging.yaml"
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✅ Staging ingress deployed" -ForegroundColor Green
        } else {
            Write-Warning "⚠️ Staging ingress deployment had issues"
        }
    }
}

# Function to show DNS configuration
function Show-DNSConfiguration {
    Write-Host "🌍 DNS Configuration Information" -ForegroundColor Green
    Write-Host "================================" -ForegroundColor Green
    
    try {
        $nameServers = az network dns zone show --name $DomainName --resource-group "eShopCleverRG" --query nameServers -o table 2>$null
        
        if ($nameServers) {
            Write-Host "📋 Configure these name servers at your domain registrar:" -ForegroundColor Yellow
            Write-Host $nameServers -ForegroundColor Cyan
        } else {
            Write-Warning "⚠️ Could not retrieve name servers. Check DNS zone deployment."
        }
    } catch {
        Write-Warning "⚠️ Could not retrieve DNS configuration"
    }
    
    Write-Host ""
    Write-Host "📝 Next manual steps:" -ForegroundColor Yellow
    Write-Host "1. Log into your domain registrar (GoDaddy, Namecheap, etc.)"
    Write-Host "2. Replace the default name servers with the Azure DNS name servers above"
    Write-Host "3. Wait for DNS propagation (15-30 minutes, up to 48 hours)"
    Write-Host "4. Run the verification script: .\verify-custom-domain.ps1"
}

# Function to verify deployment
function Test-Deployment {
    Write-Host "🔍 Running deployment verification..." -ForegroundColor Yellow
    
    if ($DryRun) {
        Write-Host "💡 DRY RUN: Would run verification tests" -ForegroundColor Magenta
        return
    }
    
    if (Test-Path "verify-custom-domain.ps1") {
        & ".\verify-custom-domain.ps1"
    } else {
        Write-Warning "⚠️ Verification script not found"
    }
}

# Main execution
try {
    Write-Host "Starting deployment process..." -ForegroundColor Green
    
    # Step 1: Check prerequisites
    Test-Prerequisites
    
    # Step 2: Deploy infrastructure (DNS zone)
    if (-not $SkipDNSZone) {
        Deploy-Infrastructure
    } else {
        Write-Host "⏭️ Skipping DNS zone deployment (--SkipDNSZone specified)" -ForegroundColor Yellow
    }
    
    # Step 3: Set up ingress infrastructure
    Deploy-IngressInfrastructure
    
    # Step 4: Get ingress IP
    $ingressIP = Get-IngressIP
    
    # Step 5: Update DNS records
    Update-DNSRecords -IngressIP $ingressIP
    
    # Step 6: Deploy application ingress
    Deploy-ApplicationIngress
    
    # Step 7: Show DNS configuration instructions
    Show-DNSConfiguration
    
    # Step 8: Run verification (optional)
    Write-Host ""
    Write-Host "🎉 Deployment completed successfully!" -ForegroundColor Green
    Write-Host "⏰ Waiting 2 minutes before running verification..." -ForegroundColor Yellow
    
    if (-not $DryRun) {
        Start-Sleep -Seconds 120
        Test-Deployment
    }
    
    Write-Host ""
    Write-Host "🌟 eShopOnWeb custom domain deployment complete!" -ForegroundColor Green
    Write-Host "🌍 Your site will be available at: https://$DomainName" -ForegroundColor Cyan
    Write-Host "🧪 Staging site: https://staging.$DomainName" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "⚠️ Remember to configure your domain registrar with the DNS name servers shown above!" -ForegroundColor Yellow
    
} catch {
    Write-Host "❌ Deployment failed: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}
