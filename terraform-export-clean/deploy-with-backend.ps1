# Terraform Deployment Script with Remote Backend
param(
    [Parameter(Mandatory=$false)]
    [ValidateSet("dev", "test", "prod")]
    [string]$Environment = "dev"
)

Write-Host "🚀 Deploying Terraform with Environment: $Environment" -ForegroundColor Green

# Initialize with backend
terraform init -backend-config="backend-$Environment.conf"

# Validate configuration
terraform validate

# Plan deployment
terraform plan -var-file="$Environment.tfvars" -out="terraform.tfplan"

# Apply if user confirms
$confirmation = Read-Host "Do you want to apply this plan? (y/N)"
if ($confirmation -eq 'y' -or $confirmation -eq 'Y') {
    terraform apply "terraform.tfplan"
    
    Write-Host "
✅ Deployment completed!" -ForegroundColor Green
    Write-Host "🌐 Azure Portal: https://portal.azure.com/#@cleveritgroup.onmicrosoft.com/resource/subscriptions/5f62fee3-b00a-44d2-86e5-5cf130b28b5d/resourceGroups/eShopCleverRG" -ForegroundColor Cyan
} else {
    Write-Host "❌ Deployment cancelled" -ForegroundColor Yellow
}
