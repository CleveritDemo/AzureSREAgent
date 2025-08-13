# 🔧 Azure Chaos Studio - Recreate Experiments Guide

## 📋 Prerequisites - COMPLETED ✅
- ✅ AKS cluster enabled as chaos target
- ✅ 16 chaos capabilities enabled 
- ✅ Managed identity permissions configured
- ✅ Chaos Mesh installed and verified working

## 🗑️ Step 1: Delete Existing Failed Experiments

### Via Azure Portal:
1. **Open Azure Portal** → Search for **"Chaos Studio"**
2. **Navigate to "Experiments"** in the left menu
3. **Select each experiment** and click **"Delete"**:
   - `eshoppodfailure`
   - `eshopcpustress` 
   - `eshopmemorystress`
   - `eshopnetworkdelay`

### Via Azure CLI (Alternative):
```bash
# Delete all existing experiments
az rest --method delete --url "https://management.azure.com/subscriptions/d7d7369b-a14f-43bc-a564-b4a077d170a9/resourceGroups/eShopCleverRG/providers/Microsoft.Chaos/experiments/eshoppodfailure?api-version=2023-11-01"

az rest --method delete --url "https://management.azure.com/subscriptions/d7d7369b-a14f-43bc-a564-b4a077d170a9/resourceGroups/eShopCleverRG/providers/Microsoft.Chaos/experiments/eshopcpustress?api-version=2023-11-01"

az rest --method delete --url "https://management.azure.com/subscriptions/d7d7369b-a14f-43bc-a564-b4a077d170a9/resourceGroups/eShopCleverRG/providers/Microsoft.Chaos/experiments/eshopmemorystress?api-version=2023-11-01"

az rest --method delete --url "https://management.azure.com/subscriptions/d7d7369b-a14f-43bc-a564-b4a077d170a9/resourceGroups/eShopCleverRG/providers/Microsoft.Chaos/experiments/eshopnetworkdelay?api-version=2023-11-01"
```

## 🧪 Step 2: Create New Experiments

### Experiment 1: Pod Failure Test

**Portal Steps:**
1. **Go to Chaos Studio** → **Experiments** → **Create**
2. **Basic Settings:**
   - Name: `eshop-pod-failure`
   - Resource Group: `eShopCleverRG`
   - Region: `East US`
   - Identity: `System-assigned managed identity`

3. **Experiment Designer:**
   - **Add Step** → **Add Branch** → **Add Action**
   - **Action Type:** `Pod Chaos`
   - **Target:** Select `eshopcleveraks`
   - **Capability:** `PodChaos-2.2`

4. **Action Configuration:**
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

5. **Duration:** `5 minutes`
6. **Review + Create**

### Experiment 2: CPU Stress Test

**Portal Steps:**
1. **Create New Experiment:**
   - Name: `eshop-cpu-stress`
   - Same basic settings as above

2. **Action Configuration:**
   ```json
   {
     "mode": "one",
     "selector": {
       "namespaces": ["eshop"],
       "labelSelectors": {
         "app": "eshop-webmvc"
       }
     },
     "stressors": {
       "cpu": {
         "workers": 2,
         "load": 80
       }
     },
     "duration": "120s"
   }
   ```

3. **Capability:** `StressChaos-2.2`
4. **Duration:** `5 minutes`

### Experiment 3: Memory Stress Test

**Portal Steps:**
1. **Create New Experiment:**
   - Name: `eshop-memory-stress`
   - Same basic settings as above

2. **Action Configuration:**
   ```json
   {
     "mode": "one",
     "selector": {
       "namespaces": ["eshop"],
       "labelSelectors": {
         "app": "eshop-webmvc"
       }
     },
     "stressors": {
       "memory": {
         "workers": 1,
         "size": "512MB"
       }
     },
     "duration": "120s"
   }
   ```

3. **Capability:** `StressChaos-2.2`
4. **Duration:** `5 minutes`

### Experiment 4: Network Delay Test

**Portal Steps:**
1. **Create New Experiment:**
   - Name: `eshop-network-delay`
   - Same basic settings as above

2. **Action Configuration:**
   ```json
   {
     "mode": "one", 
     "selector": {
       "namespaces": ["eshop"],
       "labelSelectors": {
         "app": "eshop-webmvc"
       }
     },
     "action": "delay",
     "delay": {
       "latency": "100ms",
       "correlation": "0",
       "jitter": "0ms"
     },
     "duration": "120s"
   }
   ```

3. **Capability:** `NetworkChaos-2.2`
4. **Duration:** `5 minutes`

## 🔐 Step 3: Configure Permissions for New Experiments

After creating the experiments, you'll need to get their new managed identity Principal IDs and configure permissions.

### Get New Principal IDs:
```bash
# Get new principal IDs for each experiment
az rest --method get --url "https://management.azure.com/subscriptions/d7d7369b-a14f-43bc-a564-b4a077d170a9/resourceGroups/eShopCleverRG/providers/Microsoft.Chaos/experiments?api-version=2023-11-01" --query "value[].{name:name, principalId:identity.principalId}" --output table
```

### Apply Permissions:
For each new Principal ID, run:
```bash
# Replace PRINCIPAL_ID with the actual ID from above
az role assignment create \
  --assignee-object-id "PRINCIPAL_ID" \
  --role "Azure Kubernetes Service Cluster User Role" \
  --scope "/subscriptions/d7d7369b-a14f-43bc-a564-b4a077d170a9/resourceGroups/eShopCleverRG/providers/Microsoft.ContainerService/managedClusters/eshopcleveraks" \
  --assignee-principal-type "ServicePrincipal"

az role assignment create \
  --assignee-object-id "PRINCIPAL_ID" \
  --role "Contributor" \
  --scope "/subscriptions/d7d7369b-a14f-43bc-a564-b4a077d170a9/resourceGroups/eShopCleverRG/providers/Microsoft.ContainerService/managedClusters/eshopcleveraks" \
  --assignee-principal-type "ServicePrincipal"
```

## 🧪 Step 4: Test Each Experiment

### Testing Order (Recommended):
1. **Start with Pod Failure** (least disruptive)
2. **Then CPU Stress** (moderate impact)
3. **Then Memory Stress** (moderate impact)  
4. **Finally Network Delay** (can affect connectivity)

### Testing Process:
1. **Monitor Baseline:**
   ```bash
   kubectl get pods -n eshop -w
   ```

2. **Start Experiment** in Azure Portal
3. **Monitor Impact** during execution
4. **Verify Recovery** after completion
5. **Wait 5 minutes** between experiments

## 📊 Success Criteria

### For Each Experiment:
- ✅ **Experiment Status:** "Running" → "Succeeded"
- ✅ **Application Availability:** No service interruption
- ✅ **Pod Recovery:** Automatic restart/recovery
- ✅ **No Errors:** Clean execution logs

## 🚨 Troubleshooting

### If Experiments Still Fail:
1. **Check Principal IDs** are correctly assigned
2. **Verify Target Selection** in experiment configuration
3. **Confirm Capabilities** are enabled on target
4. **Review JSON Configuration** for syntax errors

### Common Issues:
- **Wrong namespace:** Ensure "eshop" namespace is specified
- **Wrong labels:** Verify "app=eshop-webmvc" label exists
- **Permissions delay:** Wait 10 minutes after role assignment
- **Target not selected:** Ensure AKS cluster target is properly selected

## 📋 Quick Reference

### Target Information:
- **AKS Cluster:** `eshopcleveraks`
- **Target Type:** `Microsoft-AzureKubernetesServiceChaosMesh`
- **Namespace:** `eshop`
- **Pod Labels:** `app=eshop-webmvc`

### Available Capabilities:
- `PodChaos-2.2` (Pod failures)
- `StressChaos-2.2` (CPU/Memory stress)
- `NetworkChaos-2.2` (Network delays/faults)
- `IOChaos-2.2` (Disk I/O issues)
- `TimeChaos-2.2` (Time manipulation)

### Monitoring Commands:
```bash
# Watch pods during experiments
kubectl get pods -n eshop -w

# Check resource usage
kubectl top pods -n eshop

# View experiment status
az rest --method get --url "https://management.azure.com/subscriptions/d7d7369b-a14f-43bc-a564-b4a077d170a9/resourceGroups/eShopCleverRG/providers/Microsoft.Chaos/experiments/EXPERIMENT_NAME/executions?api-version=2023-11-01"
```

---

## 🎯 Expected Outcome

After following this guide, you should have:
1. ✅ 4 new working chaos experiments
2. ✅ Properly configured permissions  
3. ✅ Successful test executions
4. ✅ Verified application resilience

The experiments should now work correctly with the enabled chaos capabilities!
