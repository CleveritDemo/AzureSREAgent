# 📋 Simple Chaos Experiments Deployment Commands

## Copy and paste these commands one by one:

### Step 1: Initialize Terraform
```
terraform init -reconfigure -backend-config="backend-test.conf"
```

### Step 2: Validate Configuration  
```
terraform validate
```

### Step 3: Create Target Plan
```
terraform plan -target=azurerm_chaos_studio_target.aks_target -out=target.tfplan
```

### Step 4: Apply Target
```
terraform apply target.tfplan
```

### Step 5: Create Pod Failure Experiment Plan
```
terraform plan -target=azurerm_chaos_studio_experiment.pod_failure -target=azurerm_role_assignment.chaos_pod_failure_aks -target=azurerm_role_assignment.chaos_pod_failure_contributor -out=pod-failure.tfplan
```

### Step 6: Apply Pod Failure Experiment
```
terraform apply pod-failure.tfplan
```

### Step 7: Create CPU Stress Experiment Plan
```
terraform plan -target=azurerm_chaos_studio_experiment.cpu_stress -target=azurerm_role_assignment.chaos_cpu_stress_aks -target=azurerm_role_assignment.chaos_cpu_stress_contributor -out=cpu-stress.tfplan
```

### Step 8: Apply CPU Stress Experiment
```
terraform apply cpu-stress.tfplan
```

### Step 9: Create Memory Stress Experiment Plan
```
terraform plan -target=azurerm_chaos_studio_experiment.memory_stress -target=azurerm_role_assignment.chaos_memory_stress_aks -target=azurerm_role_assignment.chaos_memory_stress_contributor -out=memory-stress.tfplan
```

### Step 10: Apply Memory Stress Experiment
```
terraform apply memory-stress.tfplan
```

### Step 11: Create Network Delay Experiment Plan
```
terraform plan -target=azurerm_chaos_studio_experiment.network_delay -target=azurerm_role_assignment.chaos_network_delay_aks -target=azurerm_role_assignment.chaos_network_delay_contributor -out=network-delay.tfplan
```

### Step 12: Apply Network Delay Experiment
```
terraform apply network-delay.tfplan
```

### Step 13: Verify All Resources
```
terraform state list | findstr chaos
```

### Step 14: Get Principal IDs
```
terraform output chaos_experiments_principal_ids
```

### Step 15: Test First Experiment
```
az rest --method post --url "https://management.azure.com/subscriptions/d7d7369b-a14f-43bc-a564-b4a077d170a9/resourceGroups/eshopcleverrg/providers/Microsoft.Chaos/experiments/eshoppodfailure/start?api-version=2024-01-01"
```

---

## Alternative: Single Command Approach

If you prefer to do everything at once (after successful init):

```
terraform plan -out=all-chaos.tfplan
```

```
terraform apply all-chaos.tfplan
```

This will create ALL chaos resources in one go, but the step-by-step approach above is safer for troubleshooting.
