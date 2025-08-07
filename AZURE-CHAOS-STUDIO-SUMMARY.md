# 🔥 Azure Chaos Studio Portal Setup - Final Summary

## ✅ **Current Status**

### Infrastructure Ready:
- ✅ **AKS Cluster**: eshopcleveraks is running
- ✅ **Chaos Mesh**: Installed and running in cluster
- ✅ **Microsoft.Chaos Provider**: Registered in subscription
- ✅ **Local Monitoring**: Chaos dashboard accessible at localhost:2333
- ✅ **Application**: eShopOnWeb pods are healthy

### Active Experiments:
```powershell
# Check current running experiments
kubectl get podchaos,networkchaos,stresschaos -A
```

## 🌍 **Azure Portal Access**

### Direct Links:
1. **[Azure Chaos Studio Portal](https://portal.azure.com/#view/Microsoft_Azure_Chaos/ChaosStudio.MenuView/~/chaosExperiment)**
2. **[Container Insights Monitoring](https://portal.azure.com/#@/resource/subscriptions/5f62fee3-b00a-44d2-86e5-5cf130b28b5d/resourceGroups/eShopCleverRG/providers/Microsoft.ContainerService/managedClusters/eshopcleveraks/insights)**

## 🎯 **Next Steps to Create Portal Experiments**

### Step 1: Enable AKS as Chaos Target
1. Open **[Chaos Studio Portal](https://portal.azure.com/#view/Microsoft_Azure_Chaos/ChaosStudio.MenuView/~/chaosExperiment)**
2. Navigate to **"Targets"** in left menu
3. Click **"Enable targets"**
4. Select your **eshopcleveraks** cluster
5. Choose capabilities: **PodChaos**, **StressChaos**, **NetworkChaos**
6. Click **"Review + Enable"**

### Step 2: Create Your First Experiment
1. Go to **"Experiments"** → **"Create"** → **"New experiment"**
2. **Name**: `eshop-pod-failure-portal`
3. **Resource Group**: `eShopCleverRG`
4. **Region**: `East US`

### Step 3: Configure Pod Failure Experiment
**Target**: Select your enabled AKS cluster  
**Action Type**: Pod Chaos  
**JSON Configuration**:
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

### Step 4: Run and Monitor
1. **Start**: Click the "Start" button on your experiment
2. **Monitor**: Watch real-time progress in portal
3. **Analyze**: Review impact on application performance

## 📊 **Monitoring Integration**

### While Experiments Run, Monitor:
- **Azure Portal**: Real-time experiment status and logs
- **Container Insights**: Pod restarts, CPU/Memory usage
- **Local Dashboard**: Chaos Mesh detailed view (localhost:2333)
- **Application Logs**: `kubectl logs -f deployment/webmvc -n eshop`

### Key Metrics to Watch:
- Pod restart events
- Application response times
- Resource utilization spikes
- Error rates and exceptions
- Network latency patterns

## 🧪 **Additional Experiment Templates**

### CPU Stress Test
```json
{
  "mode": "one",
  "selector": {
    "namespaces": ["eshop"],
    "labelSelectors": {"app": "webmvc"}
  },
  "duration": "300s",
  "stressors": {
    "cpu": {"workers": 2, "load": 80}
  }
}
```

### Network Delay Test
```json
{
  "mode": "one",
  "selector": {
    "namespaces": ["eshop"],
    "labelSelectors": {"app": "webmvc"}
  },
  "action": "delay",
  "duration": "180s",
  "delay": {
    "latency": "200ms",
    "jitter": "10ms"
  }
}
```

### Memory Stress Test
```json
{
  "mode": "one",
  "selector": {
    "namespaces": ["eshop"],
    "labelSelectors": {"app": "publicapi"}
  },
  "duration": "240s",
  "stressors": {
    "memory": {"workers": 1, "size": "512MB"}
  }
}
```

## 🎮 **Using Portal Experiments for SRE Testing**

### Benefits of Portal Experiments:
- ✅ **Centralized Management**: All experiments in one place
- ✅ **Historical Tracking**: View past runs and results
- ✅ **Team Collaboration**: Share experiments with team members
- ✅ **Integrated Monitoring**: Built-in Azure Monitor integration
- ✅ **Approval Workflows**: Control who can run experiments
- ✅ **Scheduled Execution**: Run experiments on schedule

### Perfect for Azure SRE Agent Testing:
- **Real-time Impact Analysis**: See how chaos affects your system
- **Resilience Validation**: Test application recovery capabilities
- **Monitoring Integration**: Leverage full Azure observability stack
- **Documentation**: Generate reports for compliance and analysis
- **Continuous Testing**: Integrate with CI/CD pipelines

## 📚 **Documentation References**

- **[Complete Setup Guide](azure-portal-chaos-setup-guide.md)** - Detailed step-by-step instructions
- **[Monitoring Guide](chaos-monitoring-guide.md)** - Dashboard and monitoring setup
- **[KQL Queries](azure-monitor-chaos-queries.kql)** - Azure Monitor queries for analysis

## 🚀 **Quick Start Commands**

```powershell
# Open all monitoring dashboards
.\monitor-chaos-experiments.ps1 -OpenDashboards

# Check current experiment status
kubectl get podchaos,networkchaos,stresschaos -A

# Monitor application impact
kubectl get pods -n eshop --watch

# View application logs
kubectl logs -f deployment/webmvc -n eshop
```

## 💡 **Pro Tips**

1. **Start Small**: Begin with short-duration experiments
2. **Monitor Closely**: Keep both Azure Portal and kubectl monitoring open
3. **Document Results**: Use portal's built-in reporting features
4. **Team Coordination**: Share experiment schedules with your team
5. **Safety First**: Always have rollback procedures ready

---

**🎯 Ready to Test**: Your infrastructure is fully prepared for Azure Chaos Studio experiments. Use the portal links above to create your first managed chaos experiment and start testing your application's resilience with the Azure SRE Agent!
