# 🔥 Real-Time Chaos Experiment Monitoring Guide

## 🎯 Dashboard Access Methods

### **Method 1: Chaos Mesh Dashboard (Local)**
- **URL**: http://localhost:2333
- **Features**: Real-time experiment control, pod status, experiment history
- **Best For**: Detailed chaos experiment management

### **Method 2: Azure Portal Monitoring**
- **AKS Overview**: [Open AKS Cluster](https://portal.azure.com/#@/resource/subscriptions/5f62fee3-b00a-44d2-86e5-5cf130b28b5d/resourceGroups/eShopCleverRG/providers/Microsoft.ContainerService/managedClusters/eshopcleveraks/overview)
- **Container Insights**: [Open Insights](https://portal.azure.com/#@/resource/subscriptions/5f62fee3-b00a-44d2-86e5-5cf130b28b5d/resourceGroups/eShopCleverRG/providers/Microsoft.ContainerService/managedClusters/eshopcleveraks/insights)
- **Metrics**: [Open Metrics](https://portal.azure.com/#@/resource/subscriptions/5f62fee3-b00a-44d2-86e5-5cf130b28b5d/resourceGroups/eShopCleverRG/providers/Microsoft.ContainerService/managedClusters/eshopcleveraks/metrics)
- **Logs**: [Open Logs](https://portal.azure.com/#@/resource/subscriptions/5f62fee3-b00a-44d2-86e5-5cf130b28b5d/resourceGroups/eShopCleverRG/providers/Microsoft.ContainerService/managedClusters/eshopcleveraks/logs)

## 🚀 Quick Start Commands

```powershell
# Open all dashboards
.\monitor-chaos-experiments.ps1 -OpenDashboards

# Start new chaos experiments  
.\monitor-chaos-experiments.ps1 -RunExperiments

# View current experiment status
.\monitor-chaos-experiments.ps1

# Stop all experiments
.\monitor-chaos-experiments.ps1 -StopExperiments
```

## 📊 Azure Portal Setup Steps

### **Step 1: Access Container Insights**
1. Click the **Container Insights** link above
2. Navigate to **Containers** tab for real-time pod status
3. Use **Metrics** tab for CPU/Memory charts
4. Check **Logs** tab for KQL queries

### **Step 2: Create Custom Dashboard**
1. In Azure Portal, click **Dashboard**
2. Click **+ New dashboard** → **Blank dashboard**
3. Name it "eShop Chaos Engineering"
4. Add tiles using the queries from `azure-monitor-chaos-queries.kql`

### **Step 3: Essential Queries for Real-Time Monitoring**

**Pod Restart Monitoring:**
```kusto
KubePodInventory
| where TimeGenerated > ago(30m)
| where Namespace == "eshop"
| where RestartCount > 0
| summarize RestartEvents = sum(RestartCount) by Name, bin(TimeGenerated, 1m)
| render timechart
```

**CPU Stress Detection:**
```kusto
Perf
| where TimeGenerated > ago(30m)
| where ObjectName == "K8SContainer"
| where CounterName == "cpuUsageNanoCores"
| where InstanceName contains "eshop"
| summarize AvgCPU = avg(CounterValue) by InstanceName, bin(TimeGenerated, 1m)
| render timechart
```

**Error Rate Tracking:**
```kusto
ContainerLog
| where TimeGenerated > ago(30m)
| where LogEntry contains "error" or LogEntry contains "exception"
| where Name contains "eshop"
| summarize ErrorCount = count() by Name, bin(TimeGenerated, 1m)
| render timechart
```

## 🔍 What to Watch During Experiments

### **In Chaos Mesh Dashboard (localhost:2333):**
- ✅ **Experiments Tab**: See running/completed experiments
- ✅ **Events Tab**: Real-time chaos events
- ✅ **Targets Tab**: Affected pods and services

### **In Azure Portal:**
- 📈 **CPU Spikes**: During stress chaos experiments
- 🔄 **Pod Restarts**: During pod failure experiments  
- 🌐 **Network Latency**: During network delay experiments
- 📊 **Response Time**: Application performance impact
- 🚨 **Error Rates**: Application resilience testing

## ⚡ Real-Time Terminal Monitoring

Open multiple terminals for live monitoring:

```powershell
# Terminal 1: Watch pod status
kubectl get pods -n eshop --watch

# Terminal 2: Monitor resource usage
kubectl top pods -n eshop --containers --watch

# Terminal 3: Follow application logs
kubectl logs -f deployment/webmvc -n eshop

# Terminal 4: Watch chaos experiments
kubectl get podchaos,networkchaos,stresschaos -A --watch
```

## 🎯 Azure SRE Agent Testing Scenarios

### **Scenario 1: Pod Failure Recovery**
```powershell
# Start pod chaos
kubectl apply -f k8s/severe-pod-chaos.yaml

# Monitor in Azure Portal:
# - Container Insights → Containers (watch pod restarts)
# - Metrics → Pod count over time
# - Logs → Query pod restart events
```

### **Scenario 2: Resource Exhaustion** 
```powershell
# Start CPU stress
kubectl apply -f k8s/cpu-stress-chaos.yaml

# Monitor in Azure Portal:
# - Metrics → CPU utilization
# - Container Insights → Performance charts
# - Alerts → CPU threshold alerts
```

### **Scenario 3: Network Degradation**
```powershell
# Start network chaos
kubectl apply -f k8s/network-delay-chaos.yaml

# Monitor in Azure Portal:
# - Logs → Application response times
# - Metrics → Network traffic patterns
# - Container Insights → Service dependencies
```

## 📋 Monitoring Checklist

### **Before Starting Experiments:**
- [ ] Chaos Mesh dashboard accessible (localhost:2333)
- [ ] Azure Portal Container Insights open
- [ ] Custom dashboard created with KQL queries
- [ ] Terminal monitoring commands ready
- [ ] Baseline metrics captured

### **During Experiments:**
- [ ] Monitor pod restart patterns
- [ ] Track CPU/Memory utilization
- [ ] Watch error rates and logs
- [ ] Observe network performance
- [ ] Document resilience behaviors

### **After Experiments:**
- [ ] Stop all chaos experiments
- [ ] Review experiment results
- [ ] Analyze recovery times
- [ ] Document lessons learned
- [ ] Update runbooks/alerts

## 🚨 Troubleshooting

### **Dashboard Not Loading:**
```powershell
# Check port-forward status
kubectl get pods -n chaos-mesh
kubectl port-forward -n chaos-mesh svc/chaos-dashboard 2333:2333
```

### **No Data in Azure Portal:**
```powershell
# Verify Container Insights is enabled
az aks show --resource-group eShopCleverRG --name eshopcleveraks --query addonProfiles.omsAgent
```

### **Experiments Not Visible:**
```powershell
# Check chaos experiments status
kubectl get podchaos,networkchaos,stresschaos -A
kubectl describe podchaos eshop-severe-chaos -n eshop
```

## 🔗 Useful Links

- **Chaos Mesh Docs**: https://chaos-mesh.org/docs/
- **Azure Monitor KQL**: https://docs.microsoft.com/en-us/azure/azure-monitor/logs/kql-quick-reference
- **Container Insights**: https://docs.microsoft.com/en-us/azure/azure-monitor/containers/container-insights-overview
- **Azure SRE**: https://docs.microsoft.com/en-us/azure/well-architected/reliability/

---

**💡 Pro Tip**: Keep both dashboards open side-by-side for the best monitoring experience. Use Chaos Mesh for experiment control and Azure Portal for infrastructure impact analysis!
