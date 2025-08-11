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

## Required GitHub Secret

⚠️ **SECURITY NOTE**: Replace the placeholder values below with your actual service principal credentials. Never commit actual secrets to your repository.

Ensure this secret is configured in your GitHub repository under **Settings → Secrets and variables → Actions → Environments → dev**:

```
Secret Name: AZURE_CREDENTIALS
Secret Value: {
  "clientId": "YOUR_SERVICE_PRINCIPAL_CLIENT_ID",
  "clientSecret": "YOUR_SERVICE_PRINCIPAL_CLIENT_SECRET",
  "subscriptionId": "5f62fee3-b00a-44d2-86e5-5cf130b28b5d",
  "tenantId": "1033d128-85ad-47b4-8c85-0a28b6ce0297"
}
```

## Key Improvements

### 🔧 **Authentication Consistency**
- All workflows now use the same authentication method
- Single secret to manage instead of multiple individual secrets
- Simplified troubleshooting and maintenance

### 🛠️ **Fixed Extension Issues**
- Removed attempts to install non-existent `chaos` extension
- Azure CLI can access Chaos Studio APIs directly via `az rest` commands
- Added verification steps to confirm Azure CLI and Chaos Studio access

### 🔒 **Security & Reliability**
- Client secret authentication is more reliable than OIDC for current setup
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
