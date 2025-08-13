# Fix Chaos Mesh Installation - Commands Only

## Check Current State
```bash
kubectl get namespace chaos-testing
kubectl get namespace chaos-engineering
kubectl get pods --all-namespaces | grep chaos
```

## Install Chaos Mesh in chaos-testing namespace
```bash
# Create the expected namespace
kubectl create namespace chaos-testing

# Add Chaos Mesh Helm repository
helm repo add chaos-mesh https://charts.chaos-mesh.org
helm repo update

# Install Chaos Mesh in chaos-testing namespace
helm install chaos-mesh chaos-mesh/chaos-mesh -n chaos-testing --version 2.6.2 --set chaosDaemon.runtime=containerd --set chaosDaemon.socketPath=/run/containerd/containerd.sock --set dashboard.create=false

# Wait for pods to be ready
kubectl wait --for=condition=Ready pod --all -n chaos-testing --timeout=300s
```

## Verify Installation
```bash
kubectl get pods -n chaos-testing
kubectl get crd | grep chaos
```

## Alternative: Move existing installation
If Chaos Mesh is already in chaos-engineering namespace:
```bash
# Check what's in chaos-engineering
kubectl get all -n chaos-engineering

# Uninstall from wrong namespace
helm uninstall chaos-mesh -n chaos-engineering

# Install in correct namespace
kubectl create namespace chaos-testing
helm install chaos-mesh chaos-mesh/chaos-mesh -n chaos-testing --version 2.6.2 --set chaosDaemon.runtime=containerd --set chaosDaemon.socketPath=/run/containerd/containerd.sock --set dashboard.create=false
```

## Test Installation
```bash
kubectl get chaosengines -n chaos-testing
kubectl describe nodes | grep chaos-daemon
```
