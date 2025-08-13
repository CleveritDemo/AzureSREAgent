# 🔧 Chaos Studio Setup and Testing Guide

## Current Status
✅ **Permissions Fixed**: All 4 chaos experiments now have proper permissions
✅ **Chaos Mesh Installed**: Running in `chaos-engineering` namespace  
✅ **Chaos Capabilities**: Enabled - 16 different chaos capabilities available
✅ **Infrastructure Test**: Direct Chaos Mesh experiment successfully failed and recovered pod
❌ **Azure Chaos Studio Integration**: Experiments still failing despite proper setup

## Latest Test Results ✅

### Direct Chaos Mesh Test (SUCCESSFUL)
```bash
✅ Applied PodChaos to eshop-webmvc pod
✅ Pod failed and restarted automatically  
✅ Application remained available (multiple replicas)
✅ Chaos recovered successfully after 30s
✅ No data loss or service interruption
```

### Infrastructure Verification
```bash
✅ AKS Cluster: Healthy and accessible
✅ Chaos Mesh: 16 capabilities enabled
✅ eShop Application: 4 pods running (2 webmvc, 2 publicapi)
✅ Pod Labels: Correctly configured for targeting
✅ Permissions: All managed identities have proper roles
```

## Remaining Issue

### Azure Chaos Studio Experiments Still Failing
Despite having:
- ✅ Proper permissions (verified)
- ✅ Enabled chaos capabilities (16 available)
- ✅ Working Chaos Mesh infrastructure (tested)
- ✅ Correct pod labels and selectors

The Azure Chaos Studio experiments continue to fail. This suggests the experiments may need to be:
1. **Recreated** through the Azure Portal with the new target configuration
2. **Updated** to use the newly enabled capabilities
3. **Configured** with the correct target URNs

## Recommended Next Steps

### Option 1: Recreate Experiments via Portal (Recommended)
1. **Delete existing failed experiments**
2. **Create new experiments** using Azure Portal wizard
3. **Select the properly configured target** with enabled capabilities
4. **Test each experiment** individually

### Option 2: Continue with Direct Chaos Mesh
Since the infrastructure works perfectly, we can:
1. **Create chaos experiments** using native Chaos Mesh YAML
2. **Automate deployment** through Kubernetes
3. **Monitor and schedule** experiments using Kubernetes tools

## Available Chaos Capabilities
Based on our verification, the following capabilities are enabled:
- PodChaos-2.2 (Pod failures)
- StressChaos-2.2 (CPU/Memory stress)  
- NetworkChaos-2.2 (Network delays/faults)
- IOChaos-2.2 (Disk I/O faults)
- TimeChaos-2.2 (Time manipulation)
- HTTPChaos-2.2 (HTTP faults)
- DNSChaos-2.2 (DNS faults)
- KernelChaos-2.2 (Kernel faults)

## Testing Plan (Once Fixed)

### Phase 1: Individual Testing
1. **Pod Failure Test**
   - Target: `app=eshop-webmvc` in `eshop` namespace
   - Expected: One pod terminates and restarts

2. **CPU Stress Test**
   - Target: `app=eshop-webmvc` in `eshop` namespace  
   - Expected: CPU usage spikes, pods may restart

3. **Memory Stress Test**
   - Target: `app=eshop-webmvc` in `eshop` namespace
   - Expected: Memory usage increases, potential pod restarts

4. **Network Delay Test**
   - Target: `app=eshop-webmvc` in `eshop` namespace
   - Expected: Increased response times

### Phase 2: Application Resilience Verification
1. **Monitor application availability**
2. **Check load balancer behavior**
3. **Verify automatic recovery**
4. **Confirm no data loss**

## Current Environment Status

### AKS Cluster Health
```
✅ Kubernetes control plane: Running
✅ CoreDNS: Running  
✅ Metrics-server: Running
```

### eShop Application Status
```
✅ eshop-publicapi: 2/2 pods running
✅ eshop-webmvc: 2/2 pods running
```

### Chaos Mesh Components
```
✅ chaos-controller-manager: 3/3 replicas
✅ chaos-daemon: Running on all nodes
✅ chaos-dashboard: 1/1 replica
✅ chaos-dns-server: 1/1 replica
```

## Next Steps

1. **Use Azure Portal** to properly configure chaos targets and capabilities
2. **Recreate experiments** if necessary through the Portal
3. **Test each experiment** individually
4. **Document results** and create monitoring setup

## Monitoring Commands for Testing

```bash
# Monitor pods during chaos tests
kubectl get pods -n eshop -w

# Check pod resource usage
kubectl top pods -n eshop

# View pod logs
kubectl logs -f deployment/eshop-webmvc -n eshop

# Check service endpoints
kubectl get endpoints -n eshop
```

## Expected Test Results

### Successful Pod Chaos
- One pod terminates
- Kubernetes restarts the pod automatically
- Application remains available (due to multiple replicas)
- Load balancer routes traffic to healthy pods

### Successful Stress Tests
- Resource usage increases on targeted pods
- Application may show slower response times
- Pods may restart if resource limits exceeded
- System should recover after test completes
