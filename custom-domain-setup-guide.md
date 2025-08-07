# Custom Domain Configuration Guide: eshopclever

## 🌐 Overview
This guide will help you configure `eshopclever` as your custom domain for the eShopOnWeb application.

## 📋 Prerequisites
- Domain name: `eshopclever.com` (or your preferred TLD)
- Access to domain registrar for DNS configuration
- Azure AKS cluster: `eshopcleveraks`
- Current FQDN: `eshopcleverak-eshopcleverrg-5f62fe-699jrtkb.hcp.eastus.azmk8s.io`

## 🔄 Implementation Options

### Option 1: Azure DNS Zone (Recommended)
Complete Azure-managed DNS solution

### Option 2: External DNS + NGINX Ingress
Use external DNS registrar with NGINX ingress controller

### Option 3: Application Gateway + Custom Domain
Azure Application Gateway with SSL termination

## 🚀 Implementation Steps

### Step 1: Choose Your Domain Strategy

#### **Option A: Purchase eshopclever.com**
- Purchase domain from registrar (GoDaddy, Namecheap, etc.)
- Point DNS to Azure DNS servers

#### **Option B: Use Azure DNS for subdomain**
- Create `eshopclever.azure.com` or similar
- Full Azure control

#### **Option C: Use existing domain**
- If you already own a domain, create subdomain
- Example: `eshop.yourdomain.com`

### Step 2: Azure DNS Zone Setup (Option 1)

#### Create DNS Zone:
```bash
# Create Azure DNS Zone
az network dns zone create \
  --resource-group eShopCleverRG \
  --name eshopclever.com

# Get name servers for domain registrar
az network dns zone show \
  --resource-group eShopCleverRG \
  --name eshopclever.com \
  --query nameServers
```

### Step 3: SSL Certificate Configuration

#### Option 3A: Let's Encrypt (Free)
- Automatic certificate management
- 90-day renewal cycle
- Supported by cert-manager

#### Option 3B: Azure Key Vault Certificate
- Enterprise-grade certificates
- Custom CA or purchased certificates
- Longer validity periods

### Step 4: Ingress Controller Setup

We'll configure multiple ingress options for flexibility.

## 📁 File Modifications Required

1. **Update Kubernetes Ingress** (`k8s/ingress.yaml`)
2. **Create cert-manager configuration** 
3. **Update Terraform for DNS zone** (optional)
4. **Create domain verification scripts**
5. **Update deployment scripts with domain**

## 🔧 Next Steps

1. **Choose domain strategy** (eshopclever.com, subdomain, etc.)
2. **Select ingress approach** (NGINX, Application Gateway, etc.)
3. **Configure SSL strategy** (Let's Encrypt, Azure certificates, etc.)
4. **Update infrastructure and application configs**

## ⚠️ Important Considerations

- **DNS Propagation**: Changes can take 24-48 hours
- **SSL Certificates**: Setup and verification required
- **Backup Plan**: Keep current setup during transition
- **Testing**: Verify all endpoints work with new domain

Let me know your preferences for:
1. Domain name (eshopclever.com or alternative)
2. DNS management (Azure DNS vs external)
3. SSL certificate approach (Let's Encrypt vs Azure)
4. Ingress controller preference

I'll then provide the specific configuration files and commands!
