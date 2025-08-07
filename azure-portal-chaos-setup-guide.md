# 🔥 Step-by-Step Guide: Creating Chaos Studio Experiments in Azure Portal

## Overview
This guide will help you manually create Azure Chaos Studio experiments that you can run and manage directly from the Azure Portal at `https://portal.azure.com/#view/Microsoft_Azure_Chaos/ChaosStudio.MenuView/~/chaosExperiment`.

## Prerequisites Setup (Already Completed ✅)
Your AKS cluster has been configured as a Chaos Studio target with the following capabilities enabled:
- ✅ PodChaos-2.2
- ✅ StressChaos-2.2  
- ✅ NetworkChaos-2.2
- ✅ IOChaos-2.2

## 🌍 Access Azure Chaos Studio Portal

**Direct Link**: [Open Chaos Studio](https://portal.azure.com/#view/Microsoft_Azure_Chaos/ChaosStudio.MenuView/~/chaosExperiment)

## 📋 Creating Your First Experiment

### Step 1: Navigate to Experiments
1. Click the Chaos Studio link above
2. In the left menu, click **"Experiments"**
3. Click **"+ Create"** → **"New experiment"**

### Step 2: Basic Information
```
Name: eshop-pod-failure-experiment
Resource Group: eShopCleverRG
Region: East US
```

### Step 3: Experiment Designer

#### Target Selection:
1. Click **"Add target"**
2. Select your AKS cluster: **eshopcleveraks**
3. Choose target type: **Microsoft-AzureKubernetesServiceChaosMesh**
4. Click **"Add"**

#### Add Action - Pod Failure:
1. Click **"Add action"**
2. Select **"Pod Chaos"**
3. Configure the action:

**Action Configuration:**
```json
{
  "mode": "one",
  "selector": {
    "namespaces": ["eshop"],
    "labelSelectors": {
      "app": "webmvc"
    }
  },
  "action": "pod-failure",
  "duration": "60s"
}
```

**Duration**: 5 minutes
**Target**: eshopcleveraks

### Step 4: Review and Create
1. Click **"Review + create"**
2. Verify the configuration
3. Click **"Create"**

## 🧪 Additional Experiment Templates

### Experiment 2: CPU Stress Test
**Name**: `eshop-cpu-stress-experiment`

**Action Type**: Stress Chaos
**Configuration**:
```json
{
  "mode": "one",
  "selector": {
    "namespaces": ["eshop"],
    "labelSelectors": {
      "app": "webmvc"
    }
  },
  "duration": "300s",
  "stressors": {
    "cpu": {
      "workers": 2,
      "load": 80
    }
  }
}
```

### Experiment 3: Network Delay
**Name**: `eshop-network-delay-experiment`

**Action Type**: Network Chaos
**Configuration**:
```json
{
  "mode": "one",
  "selector": {
    "namespaces": ["eshop"],
    "labelSelectors": {
      "app": "webmvc"
    }
  },
  "action": "delay",
  "duration": "180s",
  "delay": {
    "latency": "200ms",
    "correlation": "0",
    "jitter": "10ms"
  }
}
```

### Experiment 4: Memory Stress
**Name**: `eshop-memory-stress-experiment`

**Action Type**: Stress Chaos
**Configuration**:
```json
{
  "mode": "one",
  "selector": {
    "namespaces": ["eshop"],
    "labelSelectors": {
      "app": "publicapi"
    }
  },
  "duration": "240s",
  "stressors": {
    "memory": {
      "workers": 1,
      "size": "512MB"
    }
  }
}
```

## 🚀 Running Experiments from Portal

### Start an Experiment:
1. Go to **Chaos Studio** → **Experiments**
2. Click on your experiment name
3. Click **"Start"** button
4. Confirm the execution
5. Monitor real-time progress

### Monitor Execution:
- **Status Tab**: View current execution status
- **Activity Tab**: See detailed step-by-step progress
- **History Tab**: Review past executions
- **Insights Tab**: View impact metrics

## 📊 Integration with Monitoring

### Azure Monitor Integration:
1. **Container Insights**: Monitor pod restarts and resource usage
2. **Metrics**: Track CPU, memory, and network impact
3. **Logs**: Query experiment effects with KQL
4. **Alerts**: Set up notifications for experiment results

### Real-Time Monitoring Commands:
```powershell
# Watch pod status during experiments
kubectl get pods -n eshop --watch

# Monitor resource usage
kubectl top pods -n eshop --containers

# View experiment logs
kubectl logs -f deployment/webmvc -n eshop
```

## 🔍 Portal Features You'll Use

### Experiment Dashboard:
- **Real-time execution status**
- **Target health monitoring**  
- **Step-by-step progress tracking**
- **Error reporting and troubleshooting**

### History and Analytics:
- **Execution timeline**
- **Success/failure rates**
- **Performance impact analysis**
- **Comparison between runs**

### Permissions and Security:
- **Role-based access control**
- **Experiment approval workflows**
- **Audit logging**
- **Resource isolation**

## 📈 Monitoring Your Experiments

### Azure Portal Links:
- **[Chaos Studio Experiments](https://portal.azure.com/#view/Microsoft_Azure_Chaos/ChaosStudio.MenuView/~/chaosExperiment)**
- **[Container Insights](https://portal.azure.com/#@/resource/subscriptions/5f62fee3-b00a-44d2-86e5-5cf130b28b5d/resourceGroups/eShopCleverRG/providers/Microsoft.ContainerService/managedClusters/eshopcleveraks/insights)**
- **[Azure Monitor Logs](https://portal.azure.com/#@/resource/subscriptions/5f62fee3-b00a-44d2-86e5-5cf130b28b5d/resourceGroups/eShopCleverRG/providers/Microsoft.ContainerService/managedClusters/eshopcleveraks/logs)**

### Key Metrics to Watch:
- **Pod restart count**
- **CPU and memory utilization**
- **Application response times**
- **Error rates and exceptions**
- **Network latency and throughput**

## 🛡️ Best Practices

### Safety Measures:
1. **Start with short duration experiments**
2. **Test during low-traffic periods**
3. **Monitor application health continuously**
4. **Have rollback procedures ready**
5. **Document experiment results**

### Experiment Scheduling:
1. **Use business-appropriate time windows**
2. **Coordinate with team members**
3. **Set up proper monitoring and alerting**
4. **Plan for post-experiment analysis**

## 🎯 Success Criteria

After creating your experiments, you should be able to:
- ✅ **View all experiments in Azure Portal**
- ✅ **Start/stop experiments with one click**
- ✅ **Monitor real-time execution progress**
- ✅ **View detailed execution history**
- ✅ **Integrate with existing monitoring tools**
- ✅ **Generate reports for SRE analysis**

## 🔗 Additional Resources

- **[Azure Chaos Studio Documentation](https://docs.microsoft.com/en-us/azure/chaos-studio/)**
- **[Chaos Engineering Principles](https://principlesofchaos.org/)**
- **[AKS Monitoring Best Practices](https://docs.microsoft.com/en-us/azure/aks/monitor-aks)**

---

**💡 Pro Tip**: Once you create these experiments in the portal, they'll be saved and ready for future executions. You can run them anytime to test your application's resilience during different scenarios!
