# eShopOnWeb Kubernetes Deployment Status
# ==========================================
# This script checks the status of your eShop deployment on AKS

Write-Host "🔍 Checking eShop Deployment Status..." -ForegroundColor Green
Write-Host ""

# Check if kubectl is available
try {
    kubectl version --client --output=json | Out-Null
    Write-Host "✅ kubectl is available" -ForegroundColor Green
} catch {
    Write-Host "❌ kubectl is not available. Please install it first." -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "📋 Pod Status:" -ForegroundColor Yellow
kubectl get pods -n eshop

Write-Host ""
Write-Host "🌐 Service Status:" -ForegroundColor Yellow
kubectl get services -n eshop

Write-Host ""
Write-Host "📊 Deployment Status:" -ForegroundColor Yellow
kubectl get deployments -n eshop

Write-Host ""
Write-Host "🔗 Access Information:" -ForegroundColor Green
$externalIP = kubectl get service eshop-webmvc -n eshop -o jsonpath='{.status.loadBalancer.ingress[0].ip}'
if ($externalIP) {
    Write-Host "🌟 Your eShop Web MVC is available at: http://$externalIP" -ForegroundColor Cyan
    Write-Host "🔍 You can also check the Public API at: http://$externalIP/api" -ForegroundColor Cyan
} else {
    Write-Host "⏳ External IP is still being assigned. Please wait a few minutes." -ForegroundColor Yellow
}

Write-Host ""
Write-Host "📝 Useful Commands:" -ForegroundColor Yellow
Write-Host "  • View logs: kubectl logs -f deployment/eshop-webmvc -n eshop" -ForegroundColor White
Write-Host "  • Scale up: kubectl scale deployment/eshop-webmvc --replicas=3 -n eshop" -ForegroundColor White
Write-Host "  • Restart: kubectl rollout restart deployment/eshop-webmvc -n eshop" -ForegroundColor White
Write-Host "  • Delete: kubectl delete namespace eshop" -ForegroundColor White
Write-Host ""
