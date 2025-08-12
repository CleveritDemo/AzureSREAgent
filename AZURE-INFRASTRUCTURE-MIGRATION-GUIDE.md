# 🚀 Azure Infrastructure Migration Guide

## 📋 Migration Overview
This guide helps you migrate your complete Azure infrastructure to a new tenant and subscription while preserving all resource names and configurations.

## 🏗️ Current Infrastructure Inventory
Based on your Terraform state, you have:

### **Core Resources:**
- **Resource Group**: `eShopCleverRG`
- **AKS Cluster**: `eshopcleveraks`
- **Container Registry**: `eshopcleveracr`
- **SQL Server**: `eshopclever-sqlsrv`
- **SQL Database**: `eshopdb`

### **Chaos Engineering Resources:**
- **Chaos Studio Target**: AKS cluster
- **Chaos Experiments**: 
  - cpu_stress
  - memory_stress
  - network_delay
  - pod_failure

### **Supporting Resources:**
- **Firewall Rules**: SQL allow all
- **DNS Zone**: (if configured)
- **Random String**: Domain verification

## 🎯 Migration Strategy

### **Phase 1: Pre-Migration Setup**
1. **New Tenant/Subscription Preparation**
2. **Service Principal Creation**
3. **Terraform Backend Migration**
4. **Configuration Validation**

### **Phase 2: Data Backup**
1. **SQL Database Backup**
2. **Container Registry Images Export**
3. **Kubernetes Configurations Export**
4. **Chaos Experiment Configurations**

### **Phase 3: Infrastructure Deployment**
1. **Core Infrastructure**
2. **Data Migration**
3. **Application Deployment**
4. **Chaos Studio Setup**

### **Phase 4: Validation & Cutover**
1. **Functionality Testing**
2. **DNS Updates**
3. **Final Validation**

## ⚙️ Migration Prerequisites

### **New Tenant/Subscription Requirements:**
- [ ] New Azure subscription with sufficient quotas
- [ ] Owner or Contributor access
- [ ] Service Principal with required permissions
- [ ] Available resource names (check naming conflicts)

### **Current Environment Access:**
- [ ] Export permissions for Container Registry
- [ ] SQL Database backup permissions
- [ ] Kubernetes cluster access
- [ ] Terraform state access

### **Tools and Credentials:**
- [ ] Azure CLI with access to both tenants
- [ ] Terraform installed
- [ ] kubectl configured
- [ ] Docker for container image migration

## 🔧 Required Information

Please provide the following information for the new environment:

```bash
# New Environment Details
NEW_TENANT_ID="<new-tenant-id>"
NEW_SUBSCRIPTION_ID="<new-subscription-id>" 
NEW_CLIENT_ID="<new-service-principal-client-id>"
NEW_REGION="<target-region>"  # e.g., "East US"

# New Storage Account for Terraform Backend
NEW_STORAGE_ACCOUNT="<new-terraform-state-storage>"
NEW_CONTAINER_NAME="<terraform-state-container>"
NEW_RESOURCE_GROUP="<terraform-backend-rg>"
```

## 📊 Migration Checklist

### **Pre-Migration (Day -1):**
- [ ] Verify new subscription quotas
- [ ] Create Service Principal in new tenant
- [ ] Set up Terraform backend in new subscription
- [ ] Test connectivity and permissions
- [ ] Schedule maintenance window

### **Migration Day:**
- [ ] Export current infrastructure configurations
- [ ] Backup SQL databases
- [ ] Export container images
- [ ] Deploy infrastructure to new subscription
- [ ] Migrate data
- [ ] Update DNS records
- [ ] Validate all services

### **Post-Migration:**
- [ ] Monitor application performance
- [ ] Update documentation
- [ ] Update GitHub secrets
- [ ] Test chaos experiments
- [ ] Clean up old resources (after validation)

## ⚠️ Important Considerations

### **Resource Naming:**
- Some Azure resource names are globally unique (ACR, SQL Server)
- May need temporary names during migration
- Update DNS records after migration

### **Data Migration:**
- SQL Database: Use backup/restore or export/import
- Container Registry: Use docker pull/push or ACR replication
- Persistent Volumes: May require manual migration

### **Downtime Estimation:**
- **Estimated Downtime**: 2-4 hours
- **DNS Propagation**: Up to 24 hours
- **Rollback Time**: 1-2 hours if needed

## 🚀 Ready to Start Migration?

1. **Review this checklist thoroughly**
2. **Gather all required information**
3. **Test migration in a development environment first**
4. **Run the automated migration script when ready**

---

**Next Steps:**
1. Provide new tenant/subscription details
2. Run pre-migration validation
3. Execute migration script
4. Perform post-migration validation

**Emergency Contacts:**
- Current environment admin: [Your contact]
- New environment admin: [New contact]
- Escalation: [Manager/Team lead]
