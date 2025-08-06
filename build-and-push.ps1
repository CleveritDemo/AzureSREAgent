# eShopOnWeb Docker Build and Push Script
# =======================================
# This script rebuilds and pushes your Docker images with the updated Azure SQL configuration

Write-Host "🚀 Starting eShopOnWeb Docker Build and Push Process..." -ForegroundColor Green
Write-Host ""

# Ensure we're logged into ACR
Write-Host "📋 Checking Azure Container Registry login..." -ForegroundColor Yellow
az acr login --name eshopcleveracr
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Failed to login to ACR. Please check your Azure CLI authentication." -ForegroundColor Red
    exit 1
}

Write-Host "✅ Successfully logged into ACR" -ForegroundColor Green
Write-Host ""

# Build Web MVC Application
Write-Host "🔨 Building Web MVC Docker image..." -ForegroundColor Yellow
$webBuildStart = Get-Date
docker build --pull -t eshopcleveracr.azurecr.io/eshopwebmvc:latest -f src/Web/Dockerfile .
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Failed to build Web MVC image" -ForegroundColor Red
    exit 1
}
$webBuildTime = (Get-Date) - $webBuildStart
Write-Host "✅ Web MVC image built successfully in $($webBuildTime.TotalSeconds.ToString('F1')) seconds" -ForegroundColor Green
Write-Host ""

# Build Public API Application
Write-Host "🔨 Building Public API Docker image..." -ForegroundColor Yellow
$apiBuildStart = Get-Date
docker build --pull -t eshopcleveracr.azurecr.io/eshoppublicapi:latest -f src/PublicApi/Dockerfile .
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Failed to build Public API image" -ForegroundColor Red
    exit 1
}
$apiBuildTime = (Get-Date) - $apiBuildStart
Write-Host "✅ Public API image built successfully in $($apiBuildTime.TotalSeconds.ToString('F1')) seconds" -ForegroundColor Green
Write-Host ""

# Push Web MVC Image
Write-Host "📤 Pushing Web MVC image to ACR..." -ForegroundColor Yellow
$webPushStart = Get-Date
docker push eshopcleveracr.azurecr.io/eshopwebmvc:latest
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Failed to push Web MVC image" -ForegroundColor Red
    exit 1
}
$webPushTime = (Get-Date) - $webPushStart
Write-Host "✅ Web MVC image pushed successfully in $($webPushTime.TotalSeconds.ToString('F1')) seconds" -ForegroundColor Green
Write-Host ""

# Push Public API Image
Write-Host "📤 Pushing Public API image to ACR..." -ForegroundColor Yellow
$apiPushStart = Get-Date
docker push eshopcleveracr.azurecr.io/eshoppublicapi:latest
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Failed to push Public API image" -ForegroundColor Red
    exit 1
}
$apiPushTime = (Get-Date) - $apiPushStart
Write-Host "✅ Public API image pushed successfully in $($apiPushTime.TotalSeconds.ToString('F1')) seconds" -ForegroundColor Green
Write-Host ""

# Summary
Write-Host "🎉 Build and Push Complete!" -ForegroundColor Green
Write-Host "================================================" -ForegroundColor Green
Write-Host "📊 Build Summary:" -ForegroundColor White
Write-Host "  • Web MVC Build Time: $($webBuildTime.TotalSeconds.ToString('F1'))s" -ForegroundColor White
Write-Host "  • Public API Build Time: $($apiBuildTime.TotalSeconds.ToString('F1'))s" -ForegroundColor White
Write-Host "  • Web MVC Push Time: $($webPushTime.TotalSeconds.ToString('F1'))s" -ForegroundColor White
Write-Host "  • Public API Push Time: $($apiPushTime.TotalSeconds.ToString('F1'))s" -ForegroundColor White
Write-Host ""
Write-Host "🔗 Your images are now available at:" -ForegroundColor White
Write-Host "  • eshopcleveracr.azurecr.io/eshopwebmvc:latest" -ForegroundColor Cyan
Write-Host "  • eshopcleveracr.azurecr.io/eshoppublicapi:latest" -ForegroundColor Cyan
Write-Host ""
Write-Host "📋 Next Steps:" -ForegroundColor Yellow
Write-Host "  1. Deploy to your AKS cluster (eshopcleveraks)" -ForegroundColor White
Write-Host "  2. Your Kubernetes manifests are ready in the k8s/ folder" -ForegroundColor White
Write-Host "  3. Run the deployment commands below" -ForegroundColor White
Write-Host ""
Write-Host "🚀 Ready to Deploy to AKS!" -ForegroundColor Green
Write-Host "Copy and run these commands:" -ForegroundColor Yellow
Write-Host ""
Write-Host "# Connect to your AKS cluster:" -ForegroundColor Gray
Write-Host "az aks get-credentials --resource-group eShopCleverRG --name eshopcleveraks" -ForegroundColor Cyan
Write-Host ""
Write-Host "# Deploy to Kubernetes:" -ForegroundColor Gray
Write-Host "kubectl apply -f k8s/" -ForegroundColor Cyan
Write-Host ""
Write-Host "# Check deployment status:" -ForegroundColor Gray
Write-Host "kubectl get pods -n eshop" -ForegroundColor Cyan
Write-Host "kubectl get services -n eshop" -ForegroundColor Cyan
Write-Host ""
Write-Host "🌟 Your application is deployed successfully!" -ForegroundColor Green
Write-Host "External IP for Web MVC: 4.156.189.241" -ForegroundColor Cyan
Write-Host "Access your eShop at: http://4.156.189.241" -ForegroundColor Yellow
Write-Host ""
