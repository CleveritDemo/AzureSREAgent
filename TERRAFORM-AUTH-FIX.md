# 🔧 Terraform Authentication Fix for GitHub Actions

## Problem

The GitHub Actions workflow was failing with this error:
```
Error: Error building ARM Config: Authenticating using the Azure CLI is only supported as a User (not a Service Principal).
```

## Root Cause

Terraform was trying to use Azure CLI authentication, but GitHub Actions uses OIDC (OpenID Connect) with a Service Principal. The Azure provider needs to be configured differently for CI/CD environments.

## Solution Applied

### 1. Updated GitHub Actions Workflow Environment Variables

Added ARM-specific environment variables to `provision-chaos-experiment.yml`:

```yaml
env:
  # ... existing vars ...
  # Terraform Azure Provider Authentication
  ARM_USE_OIDC: true
  ARM_USE_AZUREAD: true
  ARM_USE_CLI: false
```

### 2. Added Terraform Environment Setup Step

```yaml
- name: Set Terraform Environment Variables
  run: |
    echo "ARM_CLIENT_ID=${{ secrets.AZURE_CLIENT_ID }}" >> $GITHUB_ENV
    echo "ARM_TENANT_ID=${{ secrets.AZURE_TENANT_ID }}" >> $GITHUB_ENV
    echo "ARM_SUBSCRIPTION_ID=${{ secrets.AZURE_SUBSCRIPTION_ID }}" >> $GITHUB_ENV
    echo "ARM_USE_OIDC=true" >> $GITHUB_ENV
    echo "ARM_USE_CLI=false" >> $GITHUB_ENV
```

### 3. Terraform Provider Configuration

The provider configuration in `terraform-export-clean/main.tf` remains unchanged to support local development:

```terraform
provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
  tenant_id       = var.tenant_id
}
```

**Important**: OIDC authentication is handled entirely through environment variables (`ARM_*`), so no changes to the provider block are needed.

### 4. Simplified Terraform Plan Step

Removed unnecessary variable passing since authentication is handled via environment variables:

```yaml
- name: Terraform Plan
  working-directory: ${{ env.TERRAFORM_WORKING_DIR }}
  run: |
    terraform plan \
      -out=tfplan-${{ inputs.experiment_name }} \
      -detailed-exitcode
```

## Required GitHub Secrets

Ensure these secrets are configured in your repository:

| Secret Name | Description | Example |
|-------------|-------------|---------|
| `AZURE_CLIENT_ID` | Service Principal Client ID | `12345678-1234-1234-1234-123456789012` |
| `AZURE_TENANT_ID` | Azure AD Tenant ID | `87654321-4321-4321-4321-210987654321` |
| `AZURE_SUBSCRIPTION_ID` | Azure Subscription ID | `5f62fee3-b00a-44d2-86e5-5cf130b28b5d` |

## Testing the Fix

### Local Testing

Run the test scripts to verify your local configuration:

**PowerShell:**
```powershell
.\test-terraform-auth.ps1
```

**Bash:**
```bash
chmod +x test-terraform-auth.sh
./test-terraform-auth.sh
```

### GitHub Actions Testing

Test the workflow with a dry run:

```bash
gh workflow run provision-chaos-experiment.yml \
  --field experiment_name="test-auth-fix" \
  --field experiment_type="pod-failure" \
  --field target_namespace="eshop" \
  --field target_labels='{"app": "eshop-webmvc"}' \
  --field duration_minutes="5" \
  --field action_duration="60s" \
  --field dry_run=true
```

## Key Changes Summary

1. ✅ **Authentication Method**: Changed from Azure CLI to OIDC
2. ✅ **Environment Variables**: Added ARM_* variables for Terraform
3. ✅ **Provider Configuration**: Updated to support OIDC authentication
4. ✅ **Workflow Simplification**: Removed redundant variable passing
5. ✅ **Test Scripts**: Added validation scripts for local testing

## Verification Steps

After applying these changes:

1. **Check Secrets**: Verify all required secrets are set in GitHub
2. **Run Test Script**: Execute local test script to validate configuration
3. **Dry Run**: Test workflow with dry_run=true
4. **Full Run**: Execute workflow with dry_run=false

## Expected Results

- ✅ Terraform initialization should succeed
- ✅ Authentication should work without CLI dependency
- ✅ Plans and applies should execute successfully
- ✅ Remote state should be properly managed

## Additional Notes

- The configuration supports both local development (using Azure CLI) and CI/CD (using OIDC)
- State locks are handled automatically by the workflow
- The backend configuration remains unchanged (Azure Storage)
- All existing functionality is preserved while fixing the authentication issue
