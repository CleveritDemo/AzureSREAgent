# Verify Custom Domain Configuration

param(
    [Parameter(Mandatory=$false)]
    [string]$DomainName = "eshopclever.com"
)

Write-Host "🔍 Verifying Custom Domain Configuration for $DomainName" -ForegroundColor Green

# Function to test URL
function Test-URL {
    param([string]$url)
    
    try {
        $response = Invoke-WebRequest -Uri $url -UseBasicParsing -TimeoutSec 10
        $statusCode = $response.StatusCode
        $responseTime = (Measure-Command { Invoke-WebRequest -Uri $url -UseBasicParsing -TimeoutSec 10 }).TotalMilliseconds
        
        if ($statusCode -eq 200) {
            Write-Host "  ✅ $url - Status: $statusCode (${responseTime}ms)" -ForegroundColor Green
        } else {
            Write-Host "  ⚠️ $url - Status: $statusCode" -ForegroundColor Yellow
        }
    } catch {
        Write-Host "  ❌ $url - Error: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# 1. Check DNS resolution
Write-Host "`n📍 DNS Resolution Check:" -ForegroundColor Cyan
try {
    $dnsResult = Resolve-DnsName -Name $DomainName -Type A -ErrorAction Stop
    foreach ($record in $dnsResult) {
        if ($record.Type -eq "A") {
            Write-Host "  ✅ $DomainName resolves to: $($record.IPAddress)" -ForegroundColor Green
        }
    }
} catch {
    Write-Host "  ❌ DNS resolution failed: $($_.Exception.Message)" -ForegroundColor Red
}

# Check www subdomain
try {
    $wwwResult = Resolve-DnsName -Name "www.$DomainName" -Type A -ErrorAction Stop
    foreach ($record in $wwwResult) {
        if ($record.Type -eq "A") {
            Write-Host "  ✅ www.$DomainName resolves to: $($record.IPAddress)" -ForegroundColor Green
        }
    }
} catch {
    Write-Host "  ❌ www.$DomainName DNS resolution failed: $($_.Exception.Message)" -ForegroundColor Red
}

# 2. Check Kubernetes resources
Write-Host "`n🔧 Kubernetes Resources:" -ForegroundColor Cyan

# Check ingress controller
Write-Host "`n  NGINX Ingress Controller:" -ForegroundColor Gray
try {
    $ingressPods = kubectl get pods -n ingress-nginx -l app.kubernetes.io/name=ingress-nginx --no-headers
    if ($ingressPods) {
        Write-Host "  ✅ NGINX Ingress Controller is running" -ForegroundColor Green
        
        # Get external IP
        $service = kubectl get service ingress-nginx-controller -n ingress-nginx -o json | ConvertFrom-Json
        $externalIP = $service.status.loadBalancer.ingress[0].ip
        if ($externalIP) {
            Write-Host "  📍 External IP: $externalIP" -ForegroundColor White
        }
    } else {
        Write-Host "  ❌ NGINX Ingress Controller not found" -ForegroundColor Red
    }
} catch {
    Write-Host "  ❌ Error checking ingress controller: $($_.Exception.Message)" -ForegroundColor Red
}

# Check cert-manager
Write-Host "`n  cert-manager:" -ForegroundColor Gray
try {
    $certManagerPods = kubectl get pods -n cert-manager --no-headers
    if ($certManagerPods) {
        Write-Host "  ✅ cert-manager is running" -ForegroundColor Green
    } else {
        Write-Host "  ❌ cert-manager not found" -ForegroundColor Red
    }
} catch {
    Write-Host "  ❌ Error checking cert-manager: $($_.Exception.Message)" -ForegroundColor Red
}

# Check cluster issuers
Write-Host "`n  ClusterIssuers:" -ForegroundColor Gray
try {
    $issuers = kubectl get clusterissuers --no-headers
    if ($issuers -match "letsencrypt-prod.*True") {
        Write-Host "  ✅ Let's Encrypt production issuer is ready" -ForegroundColor Green
    } else {
        Write-Host "  ❌ Let's Encrypt production issuer not ready" -ForegroundColor Red
    }
    
    if ($issuers -match "letsencrypt-staging.*True") {
        Write-Host "  ✅ Let's Encrypt staging issuer is ready" -ForegroundColor Green
    } else {
        Write-Host "  ❌ Let's Encrypt staging issuer not ready" -ForegroundColor Red
    }
} catch {
    Write-Host "  ❌ Error checking cluster issuers: $($_.Exception.Message)" -ForegroundColor Red
}

# Check ingress resources
Write-Host "`n  Ingress Resources:" -ForegroundColor Gray
try {
    $ingresses = kubectl get ingress -n eshop --no-headers
    if ($ingresses) {
        Write-Host "  ✅ Ingress resources found in eshop namespace" -ForegroundColor Green
        kubectl get ingress -n eshop
    } else {
        Write-Host "  ❌ No ingress resources found in eshop namespace" -ForegroundColor Red
    }
} catch {
    Write-Host "  ❌ Error checking ingress resources: $($_.Exception.Message)" -ForegroundColor Red
}

# Check certificates
Write-Host "`n  SSL Certificates:" -ForegroundColor Gray
try {
    $certificates = kubectl get certificates -n eshop --no-headers
    if ($certificates) {
        Write-Host "  📜 Certificate status:" -ForegroundColor White
        kubectl get certificates -n eshop
    } else {
        Write-Host "  ⚠️ No certificates found (may still be issuing)" -ForegroundColor Yellow
    }
} catch {
    Write-Host "  ❌ Error checking certificates: $($_.Exception.Message)" -ForegroundColor Red
}

# 3. HTTP/HTTPS connectivity tests
Write-Host "`n🌐 Connectivity Tests:" -ForegroundColor Cyan

Write-Host "`n  HTTP Tests:" -ForegroundColor Gray
Test-URL "http://$DomainName"
Test-URL "http://www.$DomainName"

Write-Host "`n  HTTPS Tests:" -ForegroundColor Gray
Test-URL "https://$DomainName"
Test-URL "https://www.$DomainName"

Write-Host "`n  API Endpoint Tests:" -ForegroundColor Gray
Test-URL "https://$DomainName/api"
Test-URL "https://$DomainName/swagger"

# 4. SSL Certificate validation
Write-Host "`n🔒 SSL Certificate Check:" -ForegroundColor Cyan
try {
    $request = [System.Net.WebRequest]::Create("https://$DomainName")
    $request.GetResponse() | Out-Null
    $cert = $request.ServicePoint.Certificate
    
    if ($cert) {
        $cert2 = [System.Security.Cryptography.X509Certificates.X509Certificate2]$cert
        Write-Host "  ✅ SSL Certificate found" -ForegroundColor Green
        Write-Host "  📋 Subject: $($cert2.Subject)" -ForegroundColor White
        Write-Host "  📋 Issuer: $($cert2.Issuer)" -ForegroundColor White
        Write-Host "  📅 Valid from: $($cert2.NotBefore)" -ForegroundColor White
        Write-Host "  📅 Valid until: $($cert2.NotAfter)" -ForegroundColor White
        
        $daysUntilExpiry = ($cert2.NotAfter - (Get-Date)).Days
        if ($daysUntilExpiry -gt 30) {
            Write-Host "  ✅ Certificate expires in $daysUntilExpiry days" -ForegroundColor Green
        } elseif ($daysUntilExpiry -gt 7) {
            Write-Host "  ⚠️ Certificate expires in $daysUntilExpiry days" -ForegroundColor Yellow
        } else {
            Write-Host "  ❌ Certificate expires in $daysUntilExpiry days!" -ForegroundColor Red
        }
    }
} catch {
    Write-Host "  ❌ SSL Certificate check failed: $($_.Exception.Message)" -ForegroundColor Red
}

# 5. Performance tests
Write-Host "`n⚡ Performance Check:" -ForegroundColor Cyan
try {
    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    $response = Invoke-WebRequest -Uri "https://$DomainName" -UseBasicParsing -TimeoutSec 30
    $stopwatch.Stop()
    
    $responseTime = $stopwatch.ElapsedMilliseconds
    $responseSize = $response.RawContentLength
    
    Write-Host "  📊 Response time: ${responseTime}ms" -ForegroundColor White
    Write-Host "  📦 Response size: ${responseSize} bytes" -ForegroundColor White
    
    if ($responseTime -lt 2000) {
        Write-Host "  ✅ Good response time" -ForegroundColor Green
    } elseif ($responseTime -lt 5000) {
        Write-Host "  ⚠️ Moderate response time" -ForegroundColor Yellow
    } else {
        Write-Host "  ❌ Slow response time" -ForegroundColor Red
    }
} catch {
    Write-Host "  ❌ Performance test failed: $($_.Exception.Message)" -ForegroundColor Red
}

# Summary
Write-Host "`n📊 Verification Summary" -ForegroundColor Magenta
Write-Host "======================" -ForegroundColor Magenta

Write-Host "`n🎯 Quick Test URLs:" -ForegroundColor Yellow
Write-Host "  Main site: https://$DomainName" -ForegroundColor White
Write-Host "  API docs: https://$DomainName/swagger" -ForegroundColor White
Write-Host "  Health check: https://$DomainName/health" -ForegroundColor White

Write-Host "`n🔧 Troubleshooting Commands:" -ForegroundColor Yellow
Write-Host "  kubectl get ingress -n eshop" -ForegroundColor Gray
Write-Host "  kubectl get certificates -n eshop" -ForegroundColor Gray
Write-Host "  kubectl describe certificate eshopclever-tls -n eshop" -ForegroundColor Gray
Write-Host "  kubectl logs -n cert-manager deployment/cert-manager" -ForegroundColor Gray
Write-Host "  kubectl logs -n ingress-nginx deployment/ingress-nginx-controller" -ForegroundColor Gray

Write-Host "`nVerification complete! 🚀" -ForegroundColor Green
