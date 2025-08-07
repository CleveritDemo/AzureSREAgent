# 🚀 eShopOnWeb Custom Domain Quick Reference

## One-Command Deployment
```powershell
# Complete automated deployment
.\deploy-custom-domain.ps1 -DomainName "eshopclever.com" -Environment "production"

# Dry run to see what would happen
.\deploy-custom-domain.ps1 -DomainName "eshopclever.com" -DryRun

# Skip DNS zone creation (if already exists)
.\deploy-custom-domain.ps1 -DomainName "eshopclever.com" -SkipDNSZone
```

## Manual Step-by-Step
```powershell
# 1. Setup ingress infrastructure
.\setup-custom-domain.ps1

# 2. Get ingress IP
kubectl get svc -n ingress-nginx ingress-nginx-controller

# 3. Deploy application
kubectl apply -f k8s\ingress-custom-domain.yaml

# 4. Verify deployment
.\verify-custom-domain.ps1
```

## Quick Status Checks
```powershell
# Check certificates
kubectl get certificate

# Check ingress
kubectl get ingress

# Check DNS
nslookup eshopclever.com

# Check pods
kubectl get pods
```

## Expected Endpoints
- **Production**: https://eshopclever.com
- **Staging**: https://staging.eshopclever.com  
- **API**: https://api.eshopclever.com
- **WWW**: https://www.eshopclever.com (redirects)

## Troubleshooting
```powershell
# Certificate issues
kubectl describe certificate eshopclever-tls

# Ingress issues  
kubectl logs -n ingress-nginx deployment/ingress-nginx-controller

# DNS issues
nslookup eshopclever.com 8.8.8.8

# Application issues
kubectl logs deployment/webmvc
```

## Rollback
```powershell
# Quick rollback to local setup
kubectl apply -f k8s\ingress.yaml

# Disable custom domain in terraform
# Set enable_custom_domain = false in production.tfvars
.\deploy-environment.ps1 -Environment production
```

---
📖 **Full Guide**: See `CUSTOM-DOMAIN-DEPLOYMENT-GUIDE.md` for complete instructions
