# 🎯 Complete Azure Chaos Studio Experiments Portal Configuration Guide

## Prerequisites Checklist
- ✅ AKS cluster `eshopcleveraks` enabled as chaos target
- ✅ 16 chaos capabilities available (verified)
- ✅ eShop application running in `eshop` namespace
- ✅ Pods labeled with `app=eshop-webmvc` and `app=eshop-publicapi`

## Portal Access
**URL**: https://portal.azure.com/#view/Microsoft_Azure_Chaos/ChaosStudioMenuBlade/~/experiments

---

# 🔬 Experiment 1: Pod Failure (eshoppodfailure)

## Step-by-Step Configuration

### 1. Basic Information
1. **Go to**: Azure Portal → Chaos Studio → Experiments
2. **Click**: "+ Create" → "New experiment"
3. **Fill in**:
   - **Subscription**: `d7d7369b-a14f-43bc-a564-b4a077d170a9`
   - **Resource Group**: `eShopCleverRG`
   - **Name**: `eshoppodfailure`
   - **Region**: `East US`

### 2. Experiment Designer
1. **Click**: "Add action" → "Add fault"
2. **Select**: `microsoft-azurekubernetesservicechaosmesh`
3. **Choose**: `PodChaos-2.2`

### 3. Target Configuration
1. **Target Resources**: Select `eshopcleveraks`
2. **Target Type**: `microsoft-azurekubernetesservicechaosmesh`

### 4. Fault Parameters
**Duration**: `5 minutes`

**JSON Configuration**:
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

### 5. Review and Create
1. **Review** all settings
2. **Click**: "Review + create"
3. **Click**: "Create"

---

# 💻 Experiment 2: CPU Stress (eshopcpustress)

## Step-by-Step Configuration

### 1. Basic Information
1. **Go to**: Azure Portal → Chaos Studio → Experiments
2. **Click**: "+ Create" → "New experiment"
3. **Fill in**:
   - **Subscription**: `d7d7369b-a14f-43bc-a564-b4a077d170a9`
   - **Resource Group**: `eShopCleverRG`
   - **Name**: `eshopcpustress`
   - **Region**: `East US`

### 2. Experiment Designer
1. **Click**: "Add action" → "Add fault"
2. **Select**: `microsoft-azurekubernetesservicechaosmesh`
3. **Choose**: `StressChaos-2.2`

### 3. Target Configuration
1. **Target Resources**: Select `eshopcleveraks`
2. **Target Type**: `microsoft-azurekubernetesservicechaosmesh`

### 4. Fault Parameters
**Duration**: `5 minutes`

**JSON Configuration**:
```json
{
  "duration": "60s",
  "stressors": {
    "cpu": {
      "workers": 1,
      "load": 80
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

### 5. Review and Create
1. **Review** all settings
2. **Click**: "Review + create"
3. **Click**: "Create"

---

# 🧠 Experiment 3: Memory Stress (eshopmemorystress)

## Step-by-Step Configuration

### 1. Basic Information
1. **Go to**: Azure Portal → Chaos Studio → Experiments
2. **Click**: "+ Create" → "New experiment"
3. **Fill in**:
   - **Subscription**: `d7d7369b-a14f-43bc-a564-b4a077d170a9`
   - **Resource Group**: `eShopCleverRG`
   - **Name**: `eshopmemorystress`
   - **Region**: `East US`

### 2. Experiment Designer
1. **Click**: "Add action" → "Add fault"
2. **Select**: `microsoft-azurekubernetesservicechaosmesh`
3. **Choose**: `StressChaos-2.2`

### 3. Target Configuration
1. **Target Resources**: Select `eshopcleveraks`
2. **Target Type**: `microsoft-azurekubernetesservicechaosmesh`

### 4. Fault Parameters
**Duration**: `5 minutes`

**JSON Configuration**:
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

### 5. Review and Create
1. **Review** all settings
2. **Click**: "Review + create"
3. **Click**: "Create"

---

# 🌐 Experiment 4: Network Delay (eshopnetworkdelay)

## Step-by-Step Configuration

### 1. Basic Information
1. **Go to**: Azure Portal → Chaos Studio → Experiments
2. **Click**: "+ Create" → "New experiment"
3. **Fill in**:
   - **Subscription**: `d7d7369b-a14f-43bc-a564-b4a077d170a9`
   - **Resource Group**: `eShopCleverRG`
   - **Name**: `eshopnetworkdelay`
   - **Region**: `East US`

### 2. Experiment Designer
1. **Click**: "Add action" → "Add fault"
2. **Select**: `microsoft-azurekubernetesservicechaosmesh`
3. **Choose**: `NetworkChaos-2.2`

### 3. Target Configuration
1. **Target Resources**: Select `eshopcleveraks`
2. **Target Type**: `microsoft-azurekubernetesservicechaosmesh`

### 4. Fault Parameters
**Duration**: `5 minutes`

**JSON Configuration**:
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

### 5. Review and Create
1. **Review** all settings
2. **Click**: "Review + create"
3. **Click**: "Create"

---

# 🔧 Post-Creation Permission Configuration

## After Creating Each Experiment

For **EACH** experiment created, you'll need the Azure Tenant owner to run these commands:

### Step 1: Get Principal ID
```bash
# Replace [EXPERIMENT-NAME] with actual experiment name
az rest --method get --url "https://management.azure.com/subscriptions/d7d7369b-a14f-43bc-a564-b4a077d170a9/resourceGroups/eshopcleverrg/providers/Microsoft.Chaos/experiments/[EXPERIMENT-NAME]?api-version=2024-01-01" --query "identity.principalId" --output tsv
```

### Step 2: Assign Permissions
```bash
# Replace [PRINCIPAL-ID] with the ID from Step 1
$principalId = "[PRINCIPAL-ID]"
$aksScope = "/subscriptions/d7d7369b-a14f-43bc-a564-b4a077d170a9/resourceGroups/eShopCleverRG/providers/Microsoft.ContainerService/managedClusters/eshopcleveraks"

# Azure Kubernetes Service Cluster User Role
az role assignment create --assignee $principalId --role "Azure Kubernetes Service Cluster User Role" --scope $aksScope

# Contributor Role
az role assignment create --assignee $principalId --role "Contributor" --scope $aksScope
```

---

# 📋 Complete JSON Reference

## All JSON Configurations Summary

### 1. Pod Failure JSON
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

### 2. CPU Stress JSON
```json
{
  "duration": "60s",
  "stressors": {
    "cpu": {
      "workers": 1,
      "load": 80
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

### 3. Memory Stress JSON
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

### 4. Network Delay JSON
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

---

# 🧪 Testing Workflow

## For Each Experiment (After Permission Configuration)

### 1. Start Experiment
```bash
az rest --method post --url "https://management.azure.com/subscriptions/d7d7369b-a14f-43bc-a564-b4a077d170a9/resourceGroups/eshopcleverrg/providers/Microsoft.Chaos/experiments/[EXPERIMENT-NAME]/start?api-version=2024-01-01"
```

### 2. Monitor Status
```bash
az rest --method get --url "https://management.azure.com/subscriptions/d7d7369b-a14f-43bc-a564-b4a077d170a9/resourceGroups/eshopcleverrg/providers/Microsoft.Chaos/experiments/[EXPERIMENT-NAME]/statuses?api-version=2024-01-01" --query "value[0]"
```

### 3. Monitor Target Pods
```bash
# For webmvc experiments (pod failure, CPU, memory)
kubectl get pods -n eshop -l app=eshop-webmvc -w

# For network delay experiment
kubectl get pods -n eshop -l app=eshop-publicapi -w
```

### 4. Check Application Health
```bash
# Monitor application accessibility
kubectl get svc -n eshop
# Test application endpoints
```

---

# ⚠️ Important Notes

## JSON Field Explanations

### Common Fields
- **`duration`**: How long each chaos burst lasts (60s = 1 minute)
- **`mode`**: `"one"` = affect one pod at a time, `"all"` = affect all matching pods
- **`selector.namespaces`**: Target namespace (`["eshop"]`)
- **`selector.labelSelectors`**: Pod selection criteria

### Pod Failure Specific
- **`action`**: `"pod-failure"` kills the pod completely

### Stress Chaos Specific
- **`stressors.cpu.workers`**: Number of CPU stress workers
- **`stressors.cpu.load`**: CPU load percentage (80 = 80%)
- **`stressors.memory.workers`**: Number of memory stress workers
- **`stressors.memory.size`**: Memory to allocate ("256MB")

### Network Chaos Specific
- **`action`**: `"delay"` adds network latency
- **`delay.latency`**: Latency to add ("100ms")
- **`delay.correlation`**: Consistency of delay ("100" = 100%)
- **`delay.jitter`**: Variation in delay ("0ms" = no variation)
- **`direction`**: `"to"` = incoming traffic, `"from"` = outgoing traffic

## Target Selection Strategy
- **Pod Failure, CPU, Memory**: Target `eshop-webmvc` (frontend application)
- **Network Delay**: Target `eshop-publicapi` (API backend)

This ensures comprehensive testing of both frontend and backend resilience.

---

# 🎯 Success Criteria

Each experiment should:
- ✅ Execute without AccessDenied errors
- ✅ Apply chaos to exactly one pod at a time
- ✅ Run for 5 minutes total (with 60-second chaos bursts)
- ✅ Allow automatic recovery between bursts
- ✅ Leave application in healthy state afterward
- ✅ Generate telemetry and monitoring data
