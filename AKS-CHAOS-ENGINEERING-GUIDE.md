# AKS-Compatible Chaos Engineering Strategy

## Working Chaos Types on AKS:

### 1. Pod Chaos (Already Working ✅)
```yaml
apiVersion: chaos-mesh.org/v1alpha1
kind: PodChaos
metadata:
  name: eshop-pod-failure
  namespace: chaos-testing
spec:
  action: pod-failure
  mode: one
  duration: "30s"
  selector:
    namespaces:
      - eshop
    labelSelectors:
      "app": "eshop-webmvc"
```

### 2. Container Kill (Alternative to network chaos)
```yaml
apiVersion: chaos-mesh.org/v1alpha1
kind: PodChaos
metadata:
  name: eshop-container-kill
  namespace: chaos-testing
spec:
  action: container-kill
  mode: one
  duration: "60s"
  selector:
    namespaces:
      - eshop
    labelSelectors:
      "app": "eshop-webmvc"
  containerNames:
    - webmvc
```

### 3. Application-Level Network Testing
Instead of manipulating network at kernel level, test resilience through:

- **Load balancer failures**: Remove backend pool members
- **DNS failures**: Use incorrect service names
- **Service mesh chaos**: If using Istio/Linkerd
- **External dependency failures**: Mock external API failures

### 4. Resource Stress (CPU/Memory)
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: stress-test
  namespace: eshop
spec:
  containers:
  - name: stress
    image: polinux/stress
    command: ["stress"]
    args: ["--cpu", "2", "--timeout", "60s"]
    resources:
      requests:
        cpu: "1"
        memory: "512Mi"
```

## Recommended Chaos Engineering Approach for AKS:

1. **Pod-level failures** (container kills, pod deletions)
2. **Node-level failures** (drain nodes, restart nodes)
3. **Application-level failures** (corrupt data, slow responses)
4. **Infrastructure failures** (scale down replicas, remove persistent volumes)
5. **External dependency simulation** (mock API failures)

## Commands to Clean Up Failed Experiments:

```bash
# Delete all failed network chaos experiments
kubectl delete networkchaos --all -n chaos-testing

# Or delete specific ones
kubectl delete networkchaos f148a466-5b07-4025-a851-dbdc66313a95 -n chaos-testing
kubectl delete networkchaos 8fb37295-0598-4a03-9e30-730ccd3d0810 -n chaos-testing
kubectl delete networkchaos bc7299f0-96d3-4ecc-9333-8cb479251a48 -n chaos-testing
```
