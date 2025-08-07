# Custom Domain Deployment Guide for eShopOnWeb

## Overview
This guide will help you deploy eShopOnWeb with a custom domain (`eshopclever.com`) using Azure Kubernetes Service (AKS), NGINX Ingress Controller, and Azure DNS.

## Prerequisites
- Domain name registered (e.g., `eshopclever.com`)
- Access to domain registrar's DNS settings
- Azure subscription with appropriate permissions
- Azure CLI configured and logged in
- kubectl configured for your AKS cluster

## Deployment Steps

### Step 1: Configure Terraform Variables

1. **Edit your environment-specific tfvars file** (e.g., `production.tfvars`):
```hcl
# Custom Domain Configuration
enable_custom_domain = true
custom_domain_name   = "eshopclever.com"
ingress_ip_address   = "0.0.0.0"  # Will be updated after ingress deployment
```

### Step 2: Deploy Infrastructure with DNS Zone

```powershell
# Navigate to terraform directory
cd c:\Users\rodri\eShopOnWeb\terraform-export-clean

# Deploy infrastructure with DNS zone
.\deploy-environment.ps1 -Environment production

# Note the output DNS name servers for later use
```

### Step 3: Set Up Custom Domain Infrastructure

```powershell
# Run the automated setup script
.\setup-custom-domain.ps1

# This will:
# - Install NGINX Ingress Controller
# - Install cert-manager for SSL certificates
# - Configure Let's Encrypt certificate issuer
```

### Step 4: Get Ingress IP Address

```powershell
# Wait for external IP assignment (may take 2-3 minutes)
kubectl get svc -n ingress-nginx ingress-nginx-controller --watch

# Once you have the external IP, note it down
$IngressIP = kubectl get svc -n ingress-nginx ingress-nginx-controller -o jsonpath='{.status.loadBalancer.ingress[0].ip}'
Write-Host "Ingress IP: $IngressIP"
```

### Step 5: Update Terraform with Ingress IP

1. **Update your tfvars file** with the actual ingress IP:
```hcl
ingress_ip_address = "20.XX.XX.XX"  # Replace with actual IP
```

2. **Re-run Terraform to update DNS records**:
```powershell
.\deploy-environment.ps1 -Environment production
```

### Step 6: Configure Domain Registrar

1. **Get Azure DNS name servers**:
```powershell
# From Terraform output or check directly
az network dns zone show --name eshopclever.com --resource-group eShopCleverRG --query nameServers -o table
```

2. **Update your domain registrar** with Azure DNS name servers:
   - Log into your domain registrar (GoDaddy, Namecheap, etc.)
   - Replace default name servers with Azure DNS name servers
   - Wait for DNS propagation (up to 48 hours, usually 15-30 minutes)

### Step 7: Deploy Application with Custom Domain

```powershell
# Deploy the ingress configuration for custom domain
kubectl apply -f k8s/ingress-custom-domain.yaml

# Deploy staging ingress (optional)
kubectl apply -f k8s/ingress-staging.yaml
```

### Step 8: Verify Deployment

```powershell
# Run the verification script
.\verify-custom-domain.ps1

# Check certificate status
kubectl get certificate -n default

# Check ingress status
kubectl get ingress -n default
```

## Expected Results

After successful deployment, you should have:

- **Main Site**: `https://eshopclever.com` - Production eShopOnWeb
- **WWW Redirect**: `https://www.eshopclever.com` - Redirects to main site
- **Staging**: `https://staging.eshopclever.com` - Staging environment
- **API**: `https://api.eshopclever.com` - API endpoints

All sites will have:
- ✅ Valid SSL certificates (Let's Encrypt)
- ✅ Automatic HTTP to HTTPS redirect
- ✅ Security headers configured
- ✅ Rate limiting protection

## Troubleshooting

### DNS Issues
```powershell
# Check DNS propagation
nslookup eshopclever.com

# Test from different DNS servers
nslookup eshopclever.com 8.8.8.8
nslookup eshopclever.com 1.1.1.1
```

### Certificate Issues
```powershell
# Check certificate request status
kubectl describe certificate eshopclever-tls -n default

# Check cert-manager logs
kubectl logs -n cert-manager deployment/cert-manager
```

### Ingress Issues
```powershell
# Check ingress controller logs
kubectl logs -n ingress-nginx deployment/ingress-nginx-controller

# Check ingress status
kubectl describe ingress eshop-ingress -n default
```

### Application Issues
```powershell
# Check pod status
kubectl get pods -n default

# Check application logs
kubectl logs deployment/webmvc -n default
kubectl logs deployment/publicapi -n default
```

## Rollback Procedures

### Disable Custom Domain
1. Edit tfvars file: `enable_custom_domain = false`
2. Run: `.\deploy-environment.ps1 -Environment production`
3. Revert to original ingress: `kubectl apply -f k8s/ingress.yaml`

### Emergency Rollback
```powershell
# Quick rollback to local domain
kubectl patch ingress eshop-ingress -n default -p '{"spec":{"rules":[{"host":"eshop.local","http":{"paths":[{"path":"/","pathType":"Prefix","backend":{"service":{"name":"webmvc","port":{"number":80}}}}]}}]}}'
```

## Security Considerations

- SSL certificates are automatically renewed by cert-manager
- Rate limiting is configured to prevent abuse
- Security headers are set for XSS and CSRF protection
- HSTS is enabled for secure connections

## Cost Considerations

- Azure DNS Zone: ~$0.50/month
- Load Balancer: ~$18/month (standard pricing)
- SSL certificates: Free (Let's Encrypt)

## Support and Maintenance

### Regular Maintenance Tasks
1. Monitor certificate expiration (auto-renewed)
2. Check ingress controller updates monthly
3. Review security headers and policies quarterly
4. Monitor DNS zone for unauthorized changes

### Monitoring Commands
```powershell
# Check overall system health
.\verify-custom-domain.ps1

# Monitor certificate renewal
kubectl get certificate --all-namespaces

# Check ingress performance
kubectl top pods -n ingress-nginx
```

## Next Steps

After successful deployment:
1. Set up monitoring and alerting
2. Configure backup procedures
3. Set up CI/CD pipeline updates
4. Consider CDN integration for global performance
5. Configure additional security policies

## Support Contacts

- **Infrastructure Issues**: Check Azure support
- **Domain Issues**: Contact domain registrar
- **Application Issues**: Check application logs and GitHub repository

---

**Note**: Keep this guide updated as your infrastructure evolves. Document any customizations or changes specific to your environment.
