# Chaos Experiment Provisioning with Terraform

This repository contains a comprehensive GitHub Actions workflow for provisioning Azure Chaos Studio experiments using Terraform while maintaining remote state synchronization.

## 🚀 Quick Start

### Using GitHub Actions Workflow

1. **Navigate to Actions**: Go to [Provision Chaos Experiment Workflow](https://github.com/CleveritDemo/AzureSREAgent/actions/workflows/provision-chaos-experiment.yml)

2. **Click "Run workflow"**

3. **Fill in the parameters**:
   - **Experiment name**: `my-pod-failure-test`
   - **Experiment type**: `pod-failure`
   - **Target namespace**: `eshop`
   - **Target labels**: `{"app": "eshop-webmvc"}`
   - **Duration (minutes)**: `5`
   - **Action duration**: `60s`
   - **Dry run**: `true` (for testing)

4. **Monitor the workflow** execution in the Actions tab

### Using GitHub CLI

```bash
gh workflow run provision-chaos-experiment.yml \
  --field experiment_name="my-pod-failure-test" \
  --field experiment_type="pod-failure" \
  --field target_namespace="eshop" \
  --field target_labels='{"app": "eshop-webmvc"}' \
  --field duration_minutes="5" \
  --field action_duration="60s" \
  --field dry_run=true
```

## 📋 Supported Experiment Types

| Type | Description | Use Case |
|------|-------------|----------|
| `pod-failure` | Kills pods randomly | Test pod restart resilience |
| `cpu-stress` | Generates CPU load | Test performance under stress |
| `memory-stress` | Consumes memory | Test memory pressure handling |
| `network-delay` | Introduces network latency | Test network resilience |
| `io-stress` | Generates I/O load | Test disk performance |

## 🔧 Management Scripts

### PowerShell (Windows)

```powershell
# List all experiments
.\manage-chaos-experiments.ps1 list

# Check experiment status
.\manage-chaos-experiments.ps1 status eshoppodfailure

# Create experiment template
.\manage-chaos-experiments.ps1 create pod-failure

# Delete experiment
.\manage-chaos-experiments.ps1 delete my-experiment

# Sync Terraform state
.\manage-chaos-experiments.ps1 sync-state

# Validate configurations
.\manage-chaos-experiments.ps1 validate
```

### Bash (Linux/macOS)

```bash
# Make script executable
chmod +x manage-chaos-experiments.sh

# List all experiments
./manage-chaos-experiments.sh list

# Check experiment status
./manage-chaos-experiments.sh status eshoppodfailure

# Create experiment template
./manage-chaos-experiments.sh create pod-failure

# Delete experiment
./manage-chaos-experiments.sh delete my-experiment

# Sync Terraform state
./manage-chaos-experiments.sh sync-state

# Validate configurations
./manage-chaos-experiments.sh validate
```

## 🏗️ Workflow Architecture

### Jobs Overview

1. **validate-inputs**: Validates input parameters and generates experiment configuration
2. **terraform-provision**: Provisions the experiment using Terraform
3. **post-provision**: Verifies the experiment and tests connectivity

### Key Features

- ✅ **Remote State Management**: Automatically syncs with Azure Storage backend
- ✅ **Input Validation**: Validates JSON format and experiment parameters
- ✅ **Dry Run Support**: Test configurations without applying changes
- ✅ **State Lock Handling**: Manages Terraform state locks automatically
- ✅ **Rollback on Failure**: Cleans up resources if provisioning fails
- ✅ **Documentation Generation**: Creates experiment documentation automatically
- ✅ **Verification**: Tests connectivity and validates provisioned resources

## 📁 Generated Files

When you provision an experiment, the workflow creates:

```
terraform-export-clean/
├── chaos-experiment-{name}.tf          # Terraform configuration
docs/
└── chaos-experiments/
    └── {name}.md                        # Experiment documentation
```

## 🔐 Required Secrets

Ensure these secrets are configured in your GitHub repository:

- `AZURE_CLIENT_ID`: Azure AD application client ID
- `AZURE_TENANT_ID`: Azure AD tenant ID
- `AZURE_SUBSCRIPTION_ID`: Azure subscription ID (also in workflow env)

## 🎯 Example Configurations

### Pod Failure Experiment

```yaml
experiment_type: pod-failure
target_labels: '{"app": "eshop-webmvc"}'
duration_minutes: "5"
action_duration: "60s"
```

### CPU Stress Experiment

```yaml
experiment_type: cpu-stress
target_labels: '{"app": "eshop-webmvc"}'
duration_minutes: "10"
action_duration: "300s"
```

### Memory Stress Experiment

```yaml
experiment_type: memory-stress
target_labels: '{"app": "eshop-publicapi"}'
duration_minutes: "5"
action_duration: "120s"
```

## 🔍 Troubleshooting

### Common Issues

1. **State Lock Error**
   ```
   Error: Error acquiring the state lock
   ```
   **Solution**: The workflow automatically handles state locks, but you can manually unlock:
   ```bash
   cd terraform-export-clean
   terraform force-unlock <LOCK_ID>
   ```

2. **Invalid JSON in target_labels**
   ```
   Error: Invalid JSON format for target_labels
   ```
   **Solution**: Ensure proper JSON format: `{"key": "value"}`

3. **Experiment Already Exists**
   ```
   Error: A resource with the ID already exists
   ```
   **Solution**: Use a different experiment name or delete the existing one

### Debug Steps

1. **Check workflow logs** in GitHub Actions
2. **Verify Azure permissions** for the service principal
3. **Validate Terraform state**:
   ```bash
   ./manage-chaos-experiments.sh sync-state
   ```
4. **Check experiment status**:
   ```bash
   ./manage-chaos-experiments.sh status <experiment-name>
   ```

## 📊 Monitoring

After provisioning, monitor your experiments through:

1. **Azure Portal**: Chaos Studio → Experiments
2. **Kubernetes**: `kubectl get pods -n eshop -w`
3. **Application Logs**: Check your application metrics
4. **GitHub Actions**: Workflow execution logs

## 🔄 Workflow Triggers

The workflow can be triggered:

- **Manually**: GitHub Actions UI or CLI
- **API**: GitHub REST API
- **Scheduled**: Add cron triggers if needed

## 📝 Best Practices

1. **Always start with dry_run=true** to validate configurations
2. **Use descriptive experiment names** with timestamps
3. **Target non-production environments** first
4. **Monitor applications** during experiments
5. **Clean up failed experiments** to avoid resource accumulation
6. **Document experiment outcomes** for team learning

## 🚨 Emergency Procedures

### Cancel Running Experiment

```bash
# Using Azure CLI
az rest --method POST \
  --url "https://management.azure.com/subscriptions/<subscription>/resourceGroups/eShopCleverRG/providers/Microsoft.Chaos/experiments/<experiment-name>/cancel?api-version=2024-01-01"

# Using management script
./manage-chaos-experiments.sh delete <experiment-name>
```

### Emergency Cleanup

```bash
# Delete all experiments
az rest --method GET \
  --url "https://management.azure.com/subscriptions/<subscription>/resourceGroups/eShopCleverRG/providers/Microsoft.Chaos/experiments?api-version=2024-01-01" \
  --query "value[].name" -o tsv | xargs -I {} az rest --method DELETE \
  --url "https://management.azure.com/subscriptions/<subscription>/resourceGroups/eShopCleverRG/providers/Microsoft.Chaos/experiments/{}?api-version=2024-01-01"
```

## 📚 Additional Resources

- [Azure Chaos Studio Documentation](https://docs.microsoft.com/en-us/azure/chaos-studio/)
- [Chaos Mesh Documentation](https://chaos-mesh.org/)
- [Terraform Azure Provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)
