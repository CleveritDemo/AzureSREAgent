# GitHub Actions Chaos Engineering Automation Guide

## Overview

This document provides comprehensive guidance for the GitHub Actions workflows created to automate chaos engineering experiments as requested by Gabriel. The automation includes scheduled experiments, manual triggers, and emergency controls.

## Created Workflows

### 1. Infrastructure Deployment (`deploy-infrastructure.yml`)
**Purpose**: Complete CI/CD pipeline for infrastructure and application deployment

**Features**:
- Terraform infrastructure deployment
- Docker image builds and pushes to ACR
- Kubernetes deployments to AKS
- Multi-environment support

**Triggers**:
- Push to main branch (paths: `infra/`, `src/`, `k8s/`)
- Manual workflow dispatch

### 2. Automated Chaos Experiments (`chaos-experiments.yml`)
**Purpose**: Scheduled execution of all chaos experiments with comprehensive monitoring

**Features**:
- Daily execution at 10:00 AM UTC
- All 4 experiments run in sequence
- Detailed monitoring and logging
- System recovery verification
- Results collection and reporting

**Experiments Included**:
- Pod Failure (eshoppodfailure)
- CPU Stress (eshopcpustress) 
- Network Delay (eshopnetworkdelay)
- Memory Stress (eshopmemorystress)

**Triggers**:
- Scheduled: Daily at 10:00 AM UTC
- Manual workflow dispatch

### 3. Manual Chaos Experiment (`manual-chaos-experiment.yml`)
**Purpose**: On-demand execution of individual chaos experiments

**Features**:
- Select specific experiment to run
- Configurable monitoring duration
- Real-time progress tracking
- Pre and post-experiment analysis
- Teams notification option

**Available Experiments**:
- Pod Failure (eshoppodfailure)
- CPU Stress (eshopcpustress)
- Network Delay (eshopnetworkdelay)
- Memory Stress (eshopmemorystress)

**Triggers**:
- Manual workflow dispatch with experiment selection

### 4. Emergency Chaos Cancellation (`emergency-chaos-cancel.yml`)
**Purpose**: Emergency controls for chaos experiment management

**Features**:
- Cancel all running experiments
- Get status of all experiments
- Force cancel specific experiment
- System recovery checks
- Emergency action logging

**Actions Available**:
- Cancel All Running Experiments
- Get Status of All Experiments
- Force Cancel Specific Experiment

**Triggers**:
- Manual workflow dispatch (emergency use only)

## Authentication Setup

### Required GitHub Secrets

To enable these workflows, you need to set up the following GitHub secrets:

```bash
AZURE_CLIENT_ID       # Service Principal Client ID
AZURE_TENANT_ID       # Azure AD Tenant ID  
AZURE_SUBSCRIPTION_ID # Azure Subscription ID (5f62fee3-b00a-44d2-86e5-5cf130b28b5d)
```

### Service Principal Setup

1. **Create Service Principal with OIDC**:
```bash
az ad sp create-for-rbac --name "github-actions-eshop" --role contributor --scopes /subscriptions/5f62fee3-b00a-44d2-86e5-5cf130b28b5d/resourceGroups/eShopCleverRG --json-auth
```

2. **Create Federated Credentials**:
```bash
az ad app federated-credential create --id <app-id> --parameters '{
  "name": "github-actions-main",
  "issuer": "https://token.actions.githubusercontent.com",
  "subject": "repo:CleveritDemo/AzureSREAgent:ref:refs/heads/main",
  "audiences": ["api://AzureADTokenExchange"]
}'
```

3. **Grant Chaos Studio Permissions**:
```bash
# Chaos Contributor role
az role assignment create --assignee <service-principal-id> --role "Chaos Studio Experiment Contributor" --scope /subscriptions/5f62fee3-b00a-44d2-86e5-5cf130b28b5d/resourceGroups/eShopCleverRG

# AKS Cluster User role
az role assignment create --assignee <service-principal-id> --role "Azure Kubernetes Service Cluster User Role" --scope /subscriptions/5f62fee3-b00a-44d2-86e5-5cf130b28b5d/resourceGroups/eShopCleverRG/providers/Microsoft.ContainerService/managedClusters/eshopcleveraks
```

### GitHub Environment Setup

1. **Create Environment**:
   - Go to repository Settings → Environments
   - Create environment named "dev"
   - Add protection rules if needed

2. **Add Secrets to Environment**:
   - Add the three Azure secrets to the "dev" environment
   - Ensure proper access controls

## Usage Instructions

### Running Scheduled Chaos Experiments

**Automatic Execution**:
- Experiments run daily at 10:00 AM UTC automatically
- Monitor progress in GitHub Actions tab

**Manual Trigger**:
1. Go to Actions → "Automated Chaos Experiments"
2. Click "Run workflow"
3. Select branch (main)
4. Click "Run workflow"

### Running Individual Experiments

1. **Navigate to Manual Workflow**:
   - Go to Actions → "Manual Chaos Experiment Trigger"

2. **Configure Execution**:
   - Click "Run workflow"
   - Select experiment type
   - Set monitoring duration (default: 10 minutes)
   - Choose Teams notification preference
   - Click "Run workflow"

3. **Monitor Progress**:
   - Watch real-time logs in the workflow run
   - View experiment status updates
   - Check system recovery verification

### Emergency Procedures

**Cancel All Running Experiments**:
1. Go to Actions → "Emergency Chaos Experiment Cancellation"
2. Click "Run workflow"
3. Select "Cancel All Running Experiments"
4. Provide reason for cancellation
5. Click "Run workflow"

**Check Experiment Status**:
1. Go to Actions → "Emergency Chaos Experiment Cancellation"
2. Click "Run workflow"
3. Select "Get Status of All Experiments"
4. Click "Run workflow"

**Force Cancel Specific Experiment**:
1. Go to Actions → "Emergency Chaos Experiment Cancellation"
2. Click "Run workflow"
3. Select "Force Cancel Specific Experiment"
4. Enter experiment name (e.g., "eshoppodfailure")
5. Provide reason
6. Click "Run workflow"

## Monitoring and Alerting

### Built-in Monitoring

**Workflow Logs**:
- Real-time experiment status
- Pod health checks
- System recovery verification
- Detailed execution summaries

**Azure Portal Integration**:
- Direct links to Chaos Studio experiments
- Execution history and details
- Resource status monitoring

### Key Metrics Tracked

1. **Experiment Execution**:
   - Start/stop times
   - Success/failure status
   - Duration and timeout handling

2. **System Impact**:
   - Pod restart counts
   - Application availability
   - Resource utilization

3. **Recovery Verification**:
   - Post-experiment pod status
   - Application endpoint health
   - System stability metrics

## Troubleshooting

### Common Issues

**Authentication Failures**:
- Verify GitHub secrets are correctly set
- Check service principal permissions
- Ensure federated credentials are configured

**Workflow Failures**:
- Check Azure CLI extension installations
- Verify resource names and subscriptions
- Review experiment configurations

**Experiment Issues**:
- Confirm Chaos Studio target is enabled
- Check AKS cluster connectivity
- Verify chaos mesh installation

### Debug Commands

**Check Service Principal**:
```bash
az ad sp show --id <client-id>
az role assignment list --assignee <client-id>
```

**Verify Chaos Studio**:
```bash
az rest --method GET --url "https://management.azure.com/subscriptions/5f62fee3-b00a-44d2-86e5-5cf130b28b5d/resourceGroups/eShopCleverRG/providers/Microsoft.Chaos/experiments?api-version=2023-11-01"
```

**Test AKS Access**:
```bash
az aks get-credentials --resource-group eShopCleverRG --name eshopcleveraks
kubectl get pods -A
```

## Security Considerations

### Access Controls

1. **Least Privilege**: Service principal has minimum required permissions
2. **Environment Protection**: GitHub environment restricts workflow access
3. **Emergency Controls**: Separate workflow for emergency cancellations

### Audit Trail

1. **GitHub Actions Logs**: Complete execution history
2. **Azure Activity Logs**: Resource-level audit trail
3. **Chaos Studio Logs**: Experiment execution details

## Best Practices

### Experiment Scheduling

1. **Business Hours**: Schedule during low-traffic periods
2. **Gradual Rollout**: Start with less critical experiments
3. **Recovery Time**: Allow sufficient time between experiments

### Monitoring

1. **Baseline Metrics**: Establish normal behavior patterns
2. **Alert Thresholds**: Set appropriate failure detection limits
3. **Recovery Verification**: Always verify system recovery

### Team Coordination

1. **Advance Notice**: Inform team of scheduled experiments
2. **Emergency Contacts**: Maintain on-call procedures
3. **Documentation**: Keep experiment results and learnings

## Support and Maintenance

### Regular Tasks

1. **Weekly**: Review experiment results and metrics
2. **Monthly**: Update experiment configurations if needed
3. **Quarterly**: Review and update service principal permissions

### Contact Information

- **Technical Manager**: Gabriel
- **Implementation**: Rodriguez (GitHub Actions automation)
- **Azure Resources**: Subscription 5f62fee3-b00a-44d2-86e5-5cf130b28b5d

---

*This automation was implemented to fulfill Gabriel's request for comprehensive chaos engineering workflow automation. All workflows are production-ready and include proper error handling, monitoring, and emergency controls.*
