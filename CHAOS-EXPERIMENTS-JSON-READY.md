# 🧪 Chaos Experiments JSON Configurations - Ready to Use

Now that Chaos Mesh is properly installed in `chaos-testing` namespace, here are the exact JSON configurations for each experiment:

## 📋 Experiment 1: Pod Failure

**Name**: `eshop-pod-failure`
**Capability**: `PodChaos-2.2`
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

---

## 💻 Experiment 2: CPU Stress

**Name**: `eshop-cpu-stress`
**Capability**: `StressChaos-2.2`
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

---

## 🧠 Experiment 3: Memory Stress

**Name**: `eshop-memory-stress`
**Capability**: `StressChaos-2.2`
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

---

## 🌐 Experiment 4: Network Delay

**Name**: `eshop-network-delay`
**Capability**: `NetworkChaos-2.2`
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

---

## 🔧 Portal Creation Steps

For each experiment:

1. **Go to**: Azure Portal → Chaos Studio → Experiments → Create
2. **Basic Settings**:
   - **Name**: Use the names above
   - **Resource Group**: `eShopCleverRG` 
   - **Region**: `East US`
   - **Identity**: System-assigned managed identity

3. **Experiment Designer**:
   - **Add Step** → **Add Branch** → **Add Action**
   - **Target**: Select `eshopcleveraks`
   - **Capability**: Use the capability specified above
   - **Duration**: `5 minutes`

4. **Action Parameters**:
   - Copy and paste the JSON configuration above

5. **Review + Create**

---

## ⚠️ Important Notes

### Target Selection
- **Pod Failure, CPU, Memory**: Target `eshop-webmvc` pods (frontend)
- **Network Delay**: Target `eshop-publicapi` pods (backend API)

### Experiment Behavior
- **Mode "one"**: Affects only one pod at a time
- **Duration "60s"**: Each chaos burst lasts 60 seconds
- **Total Duration "5 minutes"**: Experiment runs for 5 minutes with multiple bursts

### Expected Results
- ✅ No "Chaos Mesh not found" errors (now fixed!)
- ✅ Experiments should start and run successfully
- ✅ Pods will be affected according to the chaos type
- ✅ Application should remain accessible (resilience test)

---

## 🧪 Testing Commands

After creating experiments, test them with:

```bash
# Monitor target pods during experiments
kubectl get pods -n eshop -l app=eshop-webmvc -w

# For network delay experiment
kubectl get pods -n eshop -l app=eshop-publicapi -w

# Check application health
kubectl get svc -n eshop
```

---

## 🎯 Success Criteria

Each experiment should:
- ✅ Deploy without permission errors
- ✅ Execute without "Chaos Mesh not found" errors  
- ✅ Apply chaos effects to exactly one pod
- ✅ Automatically recover after 60-second bursts
- ✅ Complete the full 5-minute duration
- ✅ Leave application in healthy state

Ready to create your first experiment! 🚀
