# Test the Chaos Experiment Provisioning Workflow

# Example 1: Pod Failure Test (Dry Run)
gh workflow run provision-chaos-experiment.yml \
  --field experiment_name="test-pod-failure-$(date +%s)" \
  --field experiment_type="pod-failure" \
  --field target_namespace="eshop" \
  --field target_labels='{"app": "eshop-webmvc"}' \
  --field duration_minutes="5" \
  --field action_duration="60s" \
  --field dry_run=true

# Example 2: CPU Stress Test (Actual Run)
gh workflow run provision-chaos-experiment.yml \
  --field experiment_name="cpu-stress-test-$(date +%s)" \
  --field experiment_type="cpu-stress" \
  --field target_namespace="eshop" \
  --field target_labels='{"app": "eshop-webmvc"}' \
  --field duration_minutes="3" \
  --field action_duration="120s" \
  --field dry_run=false

# Example 3: Memory Stress Test on Public API
gh workflow run provision-chaos-experiment.yml \
  --field experiment_name="memory-stress-publicapi-$(date +%s)" \
  --field experiment_type="memory-stress" \
  --field target_namespace="eshop" \
  --field target_labels='{"app": "eshop-publicapi"}' \
  --field duration_minutes="5" \
  --field action_duration="180s" \
  --field dry_run=true

echo "Workflows triggered! Check status at:"
echo "https://github.com/CleveritDemo/AzureSREAgent/actions/workflows/provision-chaos-experiment.yml"
