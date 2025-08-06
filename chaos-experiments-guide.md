# Chaos Experiments for eShopOnWeb AKS Testing
# Use these experiments to test Azure SRE Agent response

## 🎯 Experiment 1: Pod Chaos - Kill all eShop pods
### This will kill all pods in the eshop namespace to test application resilience

**JSON Spec for Pod Chaos:**
```json
{"action":"pod-failure","mode":"all","selector":{"namespaces":["eshop"]}}
```

**Expected Impact:**
- All eShop application pods will be terminated
- Kubernetes will automatically restart them
- Users will experience temporary service interruption
- Test: Azure SRE Agent should detect the outage and provide alerts

---

## 🎯 Experiment 2: Stress Chaos - High CPU load on Web MVC
### This will create high CPU load on Web MVC pods

**JSON Spec for Stress Chaos:**
```json
{"mode":"all","selector":{"namespaces":["eshop"],"labelSelectors":{"app":"eshop-webmvc"}},"stressors":{"cpu":{"workers":4,"load":95}}}
```

**Expected Impact:**
- Web MVC pods will experience 95% CPU load
- Response times will increase significantly
- Users may experience slow page loads
- Test: Azure SRE Agent should detect performance degradation

---

## 🎯 Experiment 3: Network Chaos - Network delays
### This will add network delays to all eshop pods

**JSON Spec for Network Chaos:**
```json
{"action":"delay","mode":"all","selector":{"namespaces":["eshop"]},"delay":{"latency":"2s","correlation":"100","jitter":"0ms"}}
```

**Expected Impact:**
- All network traffic to/from eshop pods will have 2-second delays
- Database connections will be slower
- Inter-service communication will be affected
- Test: Azure SRE Agent should detect latency issues

---

## 🎯 Experiment 4: IO Chaos - Disk I/O failures
### This will cause I/O failures in application pods

**JSON Spec for IO Chaos:**
```json
{"action":"fault","mode":"all","selector":{"namespaces":["eshop"]},"errno":5,"percent":50,"path":"/app"}
```

**Expected Impact:**
- 50% of file operations will fail
- Application may crash or behave unpredictably
- Log files and temporary files will be affected
- Test: Azure SRE Agent should detect application failures

---

## 🚀 How to Create Experiments in Azure Portal

### Step 1: Navigate to Chaos Studio
1. Go to: https://portal.azure.com
2. Search for "Chaos Studio"
3. Click on "Chaos Studio"

### Step 2: Create New Experiment
1. Click "Experiments" → "Create" → "New experiment"
2. Fill in:
   - **Subscription**: Patrocinio de Microsoft Azure
   - **Resource Group**: eShopCleverRG
   - **Location**: East US
   - **Name**: (e.g., "eShop-Pod-Chaos-Test")

### Step 3: Configure Experiment
1. In Experiment Designer:
   - **Step Name**: "Break eShop Pods"
   - **Branch Name**: "Pod Failure"
   - **Action**: "Add fault"
   
2. Select fault type:
   - **AKS Chaos Mesh Pod Chaos** (for pod failures)
   - **AKS Chaos Mesh Stress Chaos** (for CPU/memory stress)
   - **AKS Chaos Mesh Network Chaos** (for network issues)
   - **AKS Chaos Mesh IO Chaos** (for I/O failures)

3. Configure fault:
   - **Duration**: 5 (minutes)
   - **jsonSpec**: Copy one of the JSON specs above

### Step 4: Select Target
1. Click "Target resources"
2. Select your AKS cluster: **eshopcleveraks**
3. Click "Next"

### Step 5: Grant Permissions
1. After creating experiment, go to your AKS cluster
2. Navigate to "Access control (IAM)"
3. Click "Add" → "Add role assignment"
4. Select "Azure Kubernetes Service Cluster Admin Role"
5. Search for your experiment name and assign it

### Step 6: Run Experiment
1. Go back to Chaos Studio
2. Select your experiment
3. Click "Start experiment"
4. Monitor the results and Azure SRE Agent responses

---

## 📊 Monitoring During Experiments

### What to Monitor:
1. **Application Availability**: http://20.253.117.38
2. **Pod Status**: `kubectl get pods -n eshop`
3. **Application Logs**: `kubectl logs -n eshop -l app=eshop-webmvc`
4. **Azure Monitor**: Check for alerts and metrics
5. **Azure SRE Agent**: Look for automated responses and recommendations

### Expected Azure SRE Agent Responses:
- **Incident Detection**: Should detect service degradation
- **Root Cause Analysis**: Should identify chaos-induced issues  
- **Recommendations**: Should suggest mitigation steps
- **Automated Actions**: May attempt self-healing actions

---

## 🔄 Recovery Verification

After each experiment:
1. Verify application returns to normal: `kubectl get pods -n eshop`
2. Test application functionality: http://20.253.117.38
3. Check all pods are healthy and running
4. Review Azure SRE Agent logs and actions taken
