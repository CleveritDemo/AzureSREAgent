# Network Chaos Logging Commands

## 1. Get All Network Chaos Experiments and Their Status
kubectl get networkchaos -A -o wide

## 2. Get Detailed Information About a Specific Network Chaos Experiment
kubectl describe networkchaos <EXPERIMENT_NAME> -n chaos-testing

## 3. Get Network Chaos Experiment Events
kubectl get events -n chaos-testing --field-selector involvedObject.kind=NetworkChaos

## 4. Get Network Chaos Controller Logs
kubectl logs -l app.kubernetes.io/component=controller-manager -n chaos-testing --tail=50

## 5. Get Chaos Daemon Logs (shows actual execution issues)
kubectl logs -l app.kubernetes.io/component=chaos-daemon -n chaos-testing --tail=50

## 6. Get Logs from a Specific Chaos Daemon Pod
kubectl get pods -n chaos-testing -l app.kubernetes.io/component=chaos-daemon
kubectl logs <CHAOS_DAEMON_POD_NAME> -n chaos-testing --tail=100

## 7. Get Network Chaos Experiment Status in JSON Format
kubectl get networkchaos <EXPERIMENT_NAME> -n chaos-testing -o json | jq '.status'

## 8. Monitor Network Chaos Experiments in Real-Time
kubectl get networkchaos -n chaos-testing -w

## 9. Get Failed Network Chaos Experiments
kubectl get networkchaos -A --field-selector=status.conditions[0].status=False

## 10. Get Network Chaos Records (detailed execution history)
kubectl get records -n chaos-testing

## 11. Check Target Pod Logs During Chaos
kubectl logs -l app=eshop-webmvc -n eshop --tail=20

## 12. Get Network Chaos Experiment YAML
kubectl get networkchaos <EXPERIMENT_NAME> -n chaos-testing -o yaml

## 13. Get Events Related to Target Pods
kubectl get events -n eshop --field-selector involvedObject.name=<POD_NAME>

## 14. Check Chaos Mesh Webhook Logs
kubectl logs -l app.kubernetes.io/component=chaos-mesh-webhook -n chaos-testing

## 15. Get All Chaos Resources Status
kubectl get chaos-mesh.org -A

# Example Usage:
# kubectl describe networkchaos f148a466-5b07-4025-a851-dbdc66313a95 -n chaos-testing
# kubectl logs -l app.kubernetes.io/component=controller-manager -n chaos-testing --tail=50 | grep "unable to flush"
