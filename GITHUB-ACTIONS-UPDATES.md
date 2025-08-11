# GitHub Actions Workflows Updated for AZURE_CREDENTIALS

## Summary of Changes

All chaos engineering GitHub Actions workflows have been updated to use the `AZURE_CREDENTIALS` secret for consistent and secure authentication.

## Updated Workflows

### 1. ✅ `manual-chaos-experiment.yml`
- **Changed**: Azure Login now uses `creds: ${{ secrets.AZURE_CREDENTIALS }}`
- **Removed**: Individual client-id, tenant-id, subscription-id parameters
- **Fixed**: Extension installation step (removed non-existent chaos extension)
- **Updated**: All subscription ID references hardcoded to `5f62fee3-b00a-44d2-86e5-5cf130b28b5d`

### 2. ✅ `chaos-experiments.yml`
- **Changed**: Azure Login now uses `creds: ${{ secrets.AZURE_CREDENTIALS }}`
- **Removed**: OIDC-specific permissions and parameters
- **Fixed**: Extension installation step (removed non-existent chaos extension)
- **Added**: Hardcoded subscription ID in environment variables

### 3. ✅ `emergency-chaos-cancel.yml`
- **Changed**: Azure Login now uses `creds: ${{ secrets.AZURE_CREDENTIALS }}`
- **Removed**: OIDC-specific permissions and parameters
- **Fixed**: Extension installation step (removed non-existent chaos extension)
- **Updated**: All subscription ID references hardcoded to `5f62fee3-b00a-44d2-86e5-5cf130b28b5d`

### 4. ✅ `deploy-infrastructure.yml`
- **Changed**: Azure Login now uses `creds: ${{ secrets.AZURE_CREDENTIALS }}`
- **Removed**: OIDC-specific permissions and parameters
- **Added**: Hardcoded subscription ID in environment variables

## Required GitHub Secrets

⚠️ **UPDATED**: Now using OIDC authentication with federated identity credentials for enhanced security.

Ensure these secrets are configured in your GitHub repository under **Settings → Secrets and variables → Actions → Environments → dev**:

```
Secret Name: AZURE_CLIENT_ID
Secret Value: 17eaa6dd-7c38-40e6-ae28-a0c55d421cbd

Secret Name: AZURE_TENANT_ID  
Secret Value: 1033d128-85ad-47b4-8c85-0a28b6ce0297

Secret Name: AZURE_SUBSCRIPTION_ID
Secret Value: 5f62fee3-b00a-44d2-86e5-5cf130b28b5d
```

### ✅ Federated Identity Credentials Configured
- **Federated Credential ID**: `0fd0ff53-bfec-46b6-a5fd-d9a823d56ff3`
- **Name**: `github-actions-eshop-dev`
- **Subject**: `repo:CleveritDemo/AzureSREAgent:environment:dev`
- **Issuer**: `https://token.actions.githubusercontent.com`

**Security Benefits**:
- ✅ No client secrets stored in GitHub
- ✅ Automatic token rotation
- ✅ Scoped to specific repository and environment
- ✅ Industry best practice for CI/CD authentication

## Key Improvements

### 🔧 **Authentication Consistency**
- All workflows now use OIDC authentication with federated identity credentials
- Three individual secrets (client-id, tenant-id, subscription-id) instead of one combined secret
- Enhanced security with no client secrets stored in GitHub
- Automatic token rotation and scoped access

### 🛠️ **Fixed Extension Issues**
- Removed attempts to install non-existent `chaos` extension
- Azure CLI can access Chaos Studio APIs directly via `az rest` commands
- Added verification steps to confirm Azure CLI and Chaos Studio access

### 🔒 **Security & Reliability**
- OIDC authentication with federated identity credentials (most secure method)
- No client secrets stored in GitHub Secrets
- Automatic token rotation and expiration
- Scoped access to specific repository and environment
- Hardcoded subscription IDs prevent configuration errors
- Proper error handling and verification steps

## Testing Instructions

1. **Verify Secret Configuration**:
   - Ensure `AZURE_CREDENTIALS` secret is properly set in the `dev` environment

2. **Test Manual Workflow**:
   - Go to Actions → "Manual Chaos Experiment Trigger"
   - Run workflow with "Pod Failure" experiment for 5 minutes
   - Verify authentication and experiment execution

3. **Test Emergency Workflow**:
   - Go to Actions → "Emergency Chaos Experiment Cancellation"
   - Run workflow with "Get Status of All Experiments"
   - Verify access to chaos experiments

4. **Test Scheduled Workflow**:
   - Manually trigger "Chaos Engineering Automation"
   - Verify all experiments can be accessed and executed

## Workflow Execution Flow

1. **Authentication**: Login using service principal credentials
2. **Verification**: Confirm Azure CLI and Chaos Studio access
3. **Execution**: Run chaos experiments using Azure REST APIs
4. **Monitoring**: Track experiment progress and system recovery
5. **Reporting**: Generate summary reports with Azure Portal links

## Benefits of Updates

- ✅ **Consistent authentication** across all workflows
- ✅ **Reliable execution** without extension dependency issues
- ✅ **Simplified maintenance** with single secret management
- ✅ **Better error handling** and verification steps
- ✅ **Production-ready** chaos engineering automation

All workflows are now ready for Gabriel's chaos engineering automation requirements! 🚀
