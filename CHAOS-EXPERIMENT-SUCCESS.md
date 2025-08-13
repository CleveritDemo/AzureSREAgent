# 🎉 Azure Chaos Studio Experiment Successfully Created!

## ✅ Completed Tasks

### 1. Experiment Creation
- **Name**: `eshop-pod-failure`
- **Type**: Pod Chaos (PodChaos-2.2)
- **Target**: eShop WebMVC pods in `eshop` namespace
- **Duration**: 5 minutes with 60-second chaos bursts
- **Mode**: One pod at a time
- **Action**: Pod failure simulation

### 2. Permissions Configured
- **Principal ID**: `26ad1f83-e606-4d40-ad29-b576f5ef915b`
- **Roles Assigned**:
  - ✅ Azure Kubernetes Service Cluster User Role
  - ✅ Contributor Role
- **Scope**: AKS cluster `eshopcleveraks`

### 3. Experiment Configuration
```json
{
  "action": "pod-failure",
  "duration": "60s", 
  "mode": "one",
  "selector": {
    "namespaces": ["eshop"],
    "labelSelectors": {
      "app": "eshop-webmvc"
    }
  }
}
```

## 🚀 Next Steps

### Create Remaining Experiments

Now that we've proven the process works, create the remaining 3 experiments:

#### 2. CPU Stress Experiment
- **Name**: `eshop-cpu-stress`
- **Type**: StressChaos-2.2
- **JSON Configuration**:
```json
{
  "duration": "60s",
  "stressors": {
    "cpu": {
      "workers": 1
    }
  },
  "mode": "one",
  "selector": {
    "namespaces": ["eshop"],
    "labelSelectors": {
      "app": "eshop-webmvc"
    }
  }
}
```

#### 3. Memory Stress Experiment
- **Name**: `eshop-memory-stress`
- **Type**: StressChaos-2.2
- **JSON Configuration**:
```json
{
  "duration": "60s",
  "stressors": {
    "memory": {
      "workers": 1,
      "size": "256MB"
    }
  },
  "mode": "one",
  "selector": {
    "namespaces": ["eshop"],
    "labelSelectors": {
      "app": "eshop-webmvc"
    }
  }
}
```

#### 4. Network Delay Experiment
- **Name**: `eshop-network-delay`
- **Type**: NetworkChaos-2.2
- **JSON Configuration**:
```json
{
  "action": "delay",
  "duration": "60s",
  "delay": {
    "latency": "100ms",
    "correlation": "100",
    "jitter": "0ms"
  },
  "direction": "to",
  "mode": "one",
  "selector": {
    "namespaces": ["eshop"],
    "labelSelectors": {
      "app": "eshop-publicapi"
    }
  }
}
```

## 🔧 Automated Permission Configuration

For each new experiment created, I'll automatically:

1. **Retrieve Principal ID**:
```bash
az rest --method get --url "https://management.azure.com/subscriptions/d7d7369b-a14f-43bc-a564-b4a077d170a9/resourceGroups/eshopcleverrg/providers/Microsoft.Chaos/experiments/[EXPERIMENT-NAME]?api-version=2024-01-01" --query "identity.principalId" --output tsv
```

2. **Assign Required Roles**:
```bash
# Azure Kubernetes Service Cluster User Role
az role assignment create \
  --assignee "[PRINCIPAL-ID]" \
  --role "Azure Kubernetes Service Cluster User Role" \
  --scope "/subscriptions/d7d7369b-a14f-43bc-a564-b4a077d170a9/resourceGroups/eShopCleverRG/providers/Microsoft.ContainerService/managedClusters/eshopcleveraks"

# Contributor Role
az role assignment create \
  --assignee "[PRINCIPAL-ID]" \
  --role "Contributor" \
  --scope "/subscriptions/d7d7369b-a14f-43bc-a564-b4a077d170a9/resourceGroups/eShopCleverRG/providers/Microsoft.ContainerService/managedClusters/eshopcleveraks"
```

## 📊 Testing Process

After each experiment creation:

1. **Start Experiment**:
```bash
az rest --method post --url "https://management.azure.com/subscriptions/d7d7369b-a14f-43bc-a564-b4a077d170a9/resourceGroups/eshopcleverrg/providers/Microsoft.Chaos/experiments/[EXPERIMENT-NAME]/start?api-version=2024-01-01"
```

2. **Monitor Execution**:
```bash
# Check experiment status
az rest --method get --url "https://management.azure.com/subscriptions/d7d7369b-a14f-43bc-a564-b4a077d170a9/resourceGroups/eshopcleverrg/providers/Microsoft.Chaos/experiments/[EXPERIMENT-NAME]/statuses?api-version=2024-01-01" --query "value[0]"

# Monitor target pods
kubectl get pods -n eshop -l app=eshop-webmvc -w
```

3. **Verify Application Resilience**:
```bash
# Check application accessibility
curl -I http://your-app-url/
```

## 🎯 Expected Results

Each experiment should:
- ✅ Execute without permission errors
- ✅ Successfully apply chaos to target pods
- ✅ Automatically recover after duration expires
- ✅ Leave application in healthy state
- ✅ Generate useful telemetry and logs

## 📈 Success Metrics

1. **Experiment Execution**: All experiments run to completion
2. **Application Resilience**: eShop remains accessible during chaos
3. **Recovery Time**: Pods recover within expected timeframes
4. **Monitoring Data**: Clear telemetry showing chaos impact and recovery

---

**Status**: 🟢 **First experiment successfully created and configured!**
**Next Action**: Create the remaining 3 experiments using the provided configurations.
