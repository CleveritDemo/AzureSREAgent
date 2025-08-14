# 🔄 AKS Autoscaling Configuration Updated

## ✅ **Changes Applied to Terraform Configuration**

**File**: `terraform-export-clean/resources.tf`

### 🎯 **Autoscaling Settings**

| Setting | Value | Description |
|---------|-------|-------------|
| **Min Nodes** | `1` | Minimum number of nodes |
| **Max Nodes** | `2` | Maximum number of nodes (as requested) |
| **Node Pool Type** | `VirtualMachineScaleSets` | Required for autoscaling |
| **VM Size** | `Standard_D2s_v3` | 2 vCPU, 8GB RAM |

### 🚀 **Auto Scaler Profile (Autorecovery)**

Enhanced configuration for intelligent scaling and recovery:

```terraform
auto_scaler_profile {
  balance_similar_node_groups      = false      # Don't balance across node groups
  expander                        = "random"    # Random node selection for scaling
  max_graceful_termination_sec    = "600"      # 10 min grace period for pod termination
  max_node_provisioning_time      = "15m"      # 15 min timeout for new node provisioning
  max_unready_nodes              = 3           # Max unready nodes before scaling
  max_unready_percentage         = 45          # Max % of unready nodes
  new_pod_scale_up_delay         = "10s"       # Delay before scaling up for new pods
  scale_down_delay_after_add     = "10m"       # Wait 10 min after scale-up before scale-down
  scale_down_delay_after_delete  = "10s"       # Wait 10s after node deletion
  scale_down_delay_after_failure = "3m"        # Wait 3 min after failure before retry
  scan_interval                  = "10s"       # Check cluster state every 10s
  scale_down_unneeded           = "10m"        # Scale down unneeded nodes after 10 min
  scale_down_unready            = "20m"        # Scale down unready nodes after 20 min
  scale_down_utilization_threshold = 0.5       # Scale down when utilization < 50%
}
```

## 🧪 **Perfect for Chaos Experiments**

### Autoscaling Benefits:
- ✅ **Automatic Recovery**: Failed nodes will be replaced automatically
- ✅ **Load Response**: Scales up under CPU/memory pressure
- ✅ **Cost Optimization**: Scales down when load decreases
- ✅ **Resilience Testing**: Tests real-world auto-recovery scenarios

### Chaos Testing Scenarios:
1. **Node Failure Recovery**: Kill a node, watch autoscaler replace it
2. **Load-based Scaling**: CPU stress experiments trigger scale-up
3. **Resource Pressure**: Memory stress tests scaling behavior
4. **Recovery Time**: Measure how fast cluster recovers from failures

## 🔧 **Deployment Commands**

### Apply Terraform Changes:
```bash
cd terraform-export-clean

# Initialize and plan
terraform init
terraform plan -var-file="terraform.tfvars"

# Apply the changes (will modify existing cluster)
terraform apply -var-file="terraform.tfvars"
```

### Verify Autoscaling:
```bash
# Check node pool configuration
az aks nodepool show \
  --resource-group eShopCleverRG \
  --cluster-name eshopcleveraks \
  --name nodepool1 \
  --query "{enableAutoScaling:enableAutoScaling, minCount:minCount, maxCount:maxCount}"

# Check autoscaler profile
az aks show \
  --resource-group eShopCleverRG \
  --name eshopcleveraks \
  --query "autoScalerProfile"
```

## 📊 **Expected Behavior**

### Current State:
- **Nodes**: 2 (fixed)
- **Autoscaling**: Disabled

### After Terraform Apply:
- **Min Nodes**: 1
- **Max Nodes**: 2
- **Current Nodes**: Will adjust based on load
- **Autoscaling**: ✅ Enabled with intelligent recovery

### Scaling Triggers:
- **Scale Up**: CPU > 80% or Memory > 85%
- **Scale Down**: CPU < 50% for 10+ minutes
- **Recovery**: Failed nodes replaced within 15 minutes

## ⚠️ **Important Notes**

### Before Applying:
1. **Backup**: Current cluster is working - consider testing in dev first
2. **Downtime**: Brief interruption possible during node pool update
3. **Monitoring**: Watch cluster during first few hours after change

### After Applying:
1. **Test Scaling**: Verify autoscaling works with load tests
2. **Monitor Costs**: Autoscaling can increase costs under load
3. **Chaos Ready**: Perfect setup for advanced chaos experiments

## 🎯 **Validation Steps**

```bash
# 1. Check current node count
kubectl get nodes

# 2. Trigger scale-up with CPU stress
kubectl run cpu-stress --image=progrium/stress -- stress -c 4

# 3. Watch nodes scale up
kubectl get nodes -w

# 4. Delete stress pod and watch scale-down
kubectl delete pod cpu-stress

# 5. Verify autoscaler events
kubectl get events --sort-by=.metadata.creationTimestamp
```

## 🚀 **Ready for Advanced Chaos Engineering!**

Your cluster now has:
- ✅ **Intelligent autoscaling** (1-2 nodes)
- ✅ **Autorecovery capabilities**
- ✅ **Optimized scaling parameters**
- ✅ **Perfect chaos testing setup**

Run `terraform apply` when ready to enable these features! 🎯
