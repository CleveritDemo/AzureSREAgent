# Install NGINX Ingress Controller and cert-manager for custom domain

param(
    [Parameter(Mandatory=$false)]
    [string]$DomainName = "eshopclever.com",
    
    [Parameter(Mandatory=$false)]
    [string]$Email = "admin@eshopclever.com",
    
    [Parameter(Mandatory=$false)]
    [string]$ResourceGroup = "eShopCleverRG",
    
    [Parameter(Mandatory=$false)]
    [string]$ClusterName = "eshopcleveraks"
)

Write-Host "🌐 Setting up custom domain: $DomainName" -ForegroundColor Green
Write-Host "📧 Email for Let's Encrypt: $Email" -ForegroundColor Yellow

# Get AKS credentials
Write-Host "`n🔐 Getting AKS credentials..." -ForegroundColor Cyan
az aks get-credentials --resource-group $ResourceGroup --name $ClusterName --overwrite-existing

# Check if kubectl is working
Write-Host "`n🔍 Verifying kubectl connection..." -ForegroundColor Cyan
kubectl cluster-info

# Install NGINX Ingress Controller using Helm
Write-Host "`n📦 Installing NGINX Ingress Controller..." -ForegroundColor Cyan

# Add Helm repositories
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo add jetstack https://charts.jetstack.io
helm repo update

# Install NGINX Ingress Controller
helm upgrade --install ingress-nginx ingress-nginx/ingress-nginx `
  --namespace ingress-nginx `
  --create-namespace `
  --set controller.service.loadBalancerIP="" `
  --set controller.service.annotations."service\.beta\.kubernetes\.io/azure-load-balancer-health-probe-request-path"="/healthz"

Write-Host "`n⏳ Waiting for NGINX Ingress Controller to get external IP..." -ForegroundColor Yellow
Write-Host "This may take 2-3 minutes..." -ForegroundColor Gray

# Wait for external IP
$timeout = 300 # 5 minutes
$elapsed = 0
$externalIP = ""

while ($elapsed -lt $timeout -and $externalIP -eq "") {
    Start-Sleep -Seconds 10
    $elapsed += 10
    
    try {
        $service = kubectl get service ingress-nginx-controller -n ingress-nginx -o json | ConvertFrom-Json
        $externalIP = $service.status.loadBalancer.ingress[0].ip
        
        if ($externalIP) {
            Write-Host "✅ External IP obtained: $externalIP" -ForegroundColor Green
            break
        } else {
            Write-Host "⏳ Still waiting for external IP... ($elapsed seconds)" -ForegroundColor Yellow
        }
    } catch {
        Write-Host "⏳ Still waiting for service to be ready... ($elapsed seconds)" -ForegroundColor Yellow
    }
}

if ($externalIP -eq "") {
    Write-Host "❌ Failed to get external IP within timeout. Check manually with:" -ForegroundColor Red
    Write-Host "kubectl get service ingress-nginx-controller -n ingress-nginx" -ForegroundColor Yellow
    exit 1
}

# Install cert-manager
Write-Host "`n🔒 Installing cert-manager for SSL certificates..." -ForegroundColor Cyan

# Install cert-manager CRDs
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.2/cert-manager.crds.yaml

# Install cert-manager using Helm
helm upgrade --install cert-manager jetstack/cert-manager `
  --namespace cert-manager `
  --create-namespace `
  --version v1.13.2

# Wait for cert-manager to be ready
Write-Host "`n⏳ Waiting for cert-manager to be ready..." -ForegroundColor Yellow
kubectl wait --for=condition=ready pod --all -n cert-manager --timeout=300s

# Create Let's Encrypt ClusterIssuer
Write-Host "`n📜 Creating Let's Encrypt ClusterIssuer..." -ForegroundColor Cyan

$clusterIssuerYaml = @"
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-prod
spec:
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
    email: $Email
    privateKeySecretRef:
      name: letsencrypt-prod
    solvers:
    - http01:
        ingress:
          class: nginx
---
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-staging
spec:
  acme:
    server: https://acme-staging-v02.api.letsencrypt.org/directory
    email: $Email
    privateKeySecretRef:
      name: letsencrypt-staging
    solvers:
    - http01:
        ingress:
          class: nginx
"@

$clusterIssuerYaml | Out-File -FilePath "cluster-issuer.yaml" -Encoding UTF8
kubectl apply -f cluster-issuer.yaml

# Create Azure DNS Zone (optional)
Write-Host "`n🌐 Creating Azure DNS Zone for $DomainName..." -ForegroundColor Cyan
try {
    az network dns zone create --resource-group $ResourceGroup --name $DomainName
    
    Write-Host "✅ DNS Zone created successfully!" -ForegroundColor Green
    Write-Host "`n📋 DNS Configuration Required:" -ForegroundColor Yellow
    Write-Host "Configure these name servers at your domain registrar:" -ForegroundColor Gray
    
    $nameServers = az network dns zone show --resource-group $ResourceGroup --name $DomainName --query nameServers --output json | ConvertFrom-Json
    foreach ($ns in $nameServers) {
        Write-Host "  • $ns" -ForegroundColor White
    }
    
    # Create A record pointing to the load balancer IP
    Write-Host "`n📍 Creating A record for $DomainName..." -ForegroundColor Cyan
    az network dns record-set a add-record `
      --resource-group $ResourceGroup `
      --zone-name $DomainName `
      --record-set-name "@" `
      --ipv4-address $externalIP
      
    # Create www A record
    az network dns record-set a add-record `
      --resource-group $ResourceGroup `
      --zone-name $DomainName `
      --record-set-name "www" `
      --ipv4-address $externalIP
      
    Write-Host "✅ DNS A records created!" -ForegroundColor Green
    
} catch {
    Write-Host "⚠️ DNS Zone creation failed (may already exist): $($_.Exception.Message)" -ForegroundColor Yellow
    Write-Host "You can create DNS records manually:" -ForegroundColor Gray
    Write-Host "  A record: $DomainName -> $externalIP" -ForegroundColor White
    Write-Host "  A record: www.$DomainName -> $externalIP" -ForegroundColor White
}

# Summary
Write-Host "`n🎉 Custom Domain Setup Complete!" -ForegroundColor Green
Write-Host "================================" -ForegroundColor Green

Write-Host "`n📊 Configuration Summary:" -ForegroundColor Cyan
Write-Host "  Domain: $DomainName" -ForegroundColor White
Write-Host "  External IP: $externalIP" -ForegroundColor White
Write-Host "  SSL Email: $Email" -ForegroundColor White
Write-Host "  Ingress Controller: NGINX" -ForegroundColor White
Write-Host "  Certificate Manager: Let's Encrypt" -ForegroundColor White

Write-Host "`n🔧 Next Steps:" -ForegroundColor Yellow
Write-Host "1. Update your domain registrar with Azure DNS name servers (if using Azure DNS)"
Write-Host "2. Wait for DNS propagation (24-48 hours)"
Write-Host "3. Apply the updated ingress configuration:"
Write-Host "   kubectl apply -f k8s/ingress-custom-domain.yaml"
Write-Host "4. Verify SSL certificate creation:"
Write-Host "   kubectl get certificates -n eshop"
Write-Host "5. Test your domain: https://$DomainName"

Write-Host "`n🌐 Manual DNS Configuration (if not using Azure DNS):" -ForegroundColor Yellow
Write-Host "Create these DNS records at your registrar:" -ForegroundColor Gray
Write-Host "  Type: A, Name: @, Value: $externalIP" -ForegroundColor White
Write-Host "  Type: A, Name: www, Value: $externalIP" -ForegroundColor White

Write-Host "`n🔍 Verification Commands:" -ForegroundColor Cyan
Write-Host "kubectl get service ingress-nginx-controller -n ingress-nginx"
Write-Host "kubectl get pods -n cert-manager"
Write-Host "kubectl get clusterissuers"
Write-Host "nslookup $DomainName"

# Clean up temporary files
Remove-Item "cluster-issuer.yaml" -ErrorAction SilentlyContinue

Write-Host "`nSetup script completed! 🚀" -ForegroundColor Green
