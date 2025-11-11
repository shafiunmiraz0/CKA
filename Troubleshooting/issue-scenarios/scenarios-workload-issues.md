# Workload Troubleshooting Scenarios: CronJob and DaemonSet

## CronJob Issue: Jobs Not Running

**Symptoms:**
- CronJob schedule passes but job doesn't run
- `.status.lastScheduleTime` not updating
- No job pods created at expected time
- Job appears suspended

## Quick Diagnosis
```bash
# Check CronJob
kubectl get cronjob -A

# Detailed CronJob info
kubectl describe cronjob <cronjob-name> -n <namespace>

# Check status fields
kubectl get cronjob <cronjob-name> -o yaml

# Look for:
# status:
#   lastScheduleTime: null  (← Problem if stuck)
#   lastSuccessfulTime: null
#   active: []

# Check related jobs
kubectl get jobs -n <namespace> --sort-by=.metadata.creationTimestamp
```

## Common Causes & Fixes

### Cause 1: CronJob Suspended
```bash
# Check if suspended
kubectl get cronjob <cronjob-name> -o jsonpath='{.spec.suspend}'
# Returns: true (← Problem)

# Resume CronJob
kubectl patch cronjob <cronjob-name> -p '{"spec":{"suspend":false}}'

# Verify resumed
kubectl get cronjob <cronjob-name> -o jsonpath='{.spec.suspend}'
# Returns: false
```

### Cause 2: Invalid Cron Schedule
```bash
# Verify cron schedule syntax
# Valid: "0 0 * * *" (every day at midnight)
# Invalid: "0 0 * * * *" (too many fields)

kubectl get cronjob <cronjob-name> -o jsonpath='{.spec.schedule}'

# Check for obvious errors
# Minute: 0-59
# Hour: 0-23
# Day of month: 1-31
# Month: 1-12
# Day of week: 0-6

# If wrong, edit and fix:
kubectl edit cronjob <cronjob-name>

# Change spec.schedule field
spec:
  schedule: "0 0 * * *"  # ← Fix this
```

### Cause 3: Service Account/RBAC Issue
```bash
# Check job pod logs for auth errors
kubectl get jobs -n <namespace>

kubectl describe job <job-name> -n <namespace>

# Check pod in job
kubectl get pods -n <namespace> -l job-name=<job-name>

kubectl logs -n <namespace> <pod-name>
# Look for: "forbidden", "unauthorized", "permission denied"

# Fix: Verify service account has permissions
kubectl get serviceaccount <sa-name> -n <namespace>

# Check RBAC roles
kubectl get rolebinding -n <namespace>
kubectl get clusterrolebinding

# If missing permissions:
kubectl create role <role-name> \
  --verb=get,list,watch \
  --resource=pods,jobs \
  -n <namespace>

kubectl create rolebinding <binding-name> \
  --role=<role-name> \
  --serviceaccount=<namespace>:<sa-name> \
  -n <namespace>
```

### Cause 4: Job Template Error
```bash
# Check CronJob spec.jobTemplate
kubectl get cronjob <cronjob-name> -o yaml | grep -A 20 "jobTemplate:"

# Common issues:
# - Image doesn't exist
# - Command missing or wrong
# - Syntax errors in container spec

# Test by creating job manually
kubectl create job test-job --image=<image-name> -n <namespace>

# If fails, fix the image or command

# Then update CronJob:
kubectl edit cronjob <cronjob-name>

# Verify jobTemplate.spec.template section
```

### Cause 5: Deadline Missed
```bash
# Check if job missed deadline
kubectl describe job <job-name> -n <namespace>

# Look for: "deadline exceeded"

# CronJob has startingDeadlineSeconds (default: 100 seconds)
# If job takes longer to start, it's skipped

kubectl get cronjob <cronjob-name> -o yaml | grep startingDeadlineSeconds

# Increase deadline:
kubectl patch cronjob <cronjob-name> \
  -p '{"spec":{"startingDeadlineSeconds":300}}'
```

## Recovery Process
```bash
# 1. Verify CronJob not suspended
kubectl get cronjob <cronjob-name> -o jsonpath='{.spec.suspend}'

# 2. Check last schedule time updates
watch 'kubectl describe cronjob <cronjob-name> | grep -A 2 "Last Schedule"'

# 3. Manually trigger job if needed (only for testing)
kubectl create job manual-test --from=cronjob/<cronjob-name> -n <namespace>

# 4. Check if new job ran
kubectl get jobs -n <namespace>
```

---

## CronJob Issue: Successful Job Not Cleaned Up

**Symptoms:**
- Jobs accumulate in cluster
- Old job pods still running
- Only failed jobs cleaned up

## Diagnosis
```bash
# Check job retention policy
kubectl get cronjob <cronjob-name> -o yaml | grep -A 5 "successfulJobsHistoryLimit\|failedJobsHistoryLimit"

# Default: successfulJobsHistoryLimit = 3
# Default: failedJobsHistoryLimit = 1

# Count old jobs
kubectl get jobs -n <namespace> | grep <cronjob-name> | wc -l

# Check job ages
kubectl get jobs -n <namespace> -o wide | grep <cronjob-name>
```

## Fix
```bash
# Set history limits to prevent accumulation
kubectl patch cronjob <cronjob-name> -p \
  '{"spec":{"successfulJobsHistoryLimit":3,"failedJobsHistoryLimit":1}}'

# Manually delete old completed jobs
kubectl delete job <old-job-name> -n <namespace>

# Delete all succeeded jobs (use with caution):
kubectl delete job -n <namespace> \
  $(kubectl get jobs -n <namespace> --field-selector status.successful=1 -o name)
```

---

## DaemonSet Issue: Not All Nodes Have Pod

**Symptoms:**
- Some nodes missing DaemonSet pod
- `kubectl get ds` shows incorrect DESIRED vs READY
- Pod not scheduled on specific node(s)

## Quick Diagnosis
```bash
# Check DaemonSet status
kubectl get daemonset -A

# Output example:
# NAME                  DESIRED READY UP-TO-DATE AVAILABLE
# kube-flannel-ds       3       2     3          2  (← Problem: only 2 ready)

# Detailed view
kubectl describe daemonset <ds-name> -n <namespace>

# Check which nodes have pods
kubectl get pods -n <namespace> -l <ds-selector> -o wide

# Compare with all nodes
kubectl get nodes

# Missing pods on which nodes?
```

## Common Causes & Fixes

### Cause 1: Node Taints Prevent Scheduling
```bash
# Check node taints
kubectl describe node <node-name> | grep Taints

# Example: Taints: node-role.kubernetes.io/master:NoSchedule

# Check DaemonSet tolerations
kubectl get daemonset <ds-name> -o yaml | grep -A 5 tolerations

# If DaemonSet missing toleration, add it:
kubectl edit daemonset <ds-name> -n <namespace>

# Add tolerations:
spec:
  template:
    spec:
      tolerations:
      - key: node-role.kubernetes.io/master
        operator: Exists
        effect: NoSchedule
```

### Cause 2: Node Selector Mismatch
```bash
# Check DaemonSet nodeSelector
kubectl get daemonset <ds-name> -o yaml | grep nodeSelector -A 5

# Check node labels
kubectl get node <node-name> --show-labels

# If nodeSelector doesn't match any labels on node:
# Either remove nodeSelector from DaemonSet:
kubectl patch daemonset <ds-name> \
  -p '{"spec":{"template":{"spec":{"nodeSelector":null}}}}'

# Or add labels to node:
kubectl label node <node-name> node-type=special
```

### Cause 3: Node Not Ready
```bash
# Check node status
kubectl get nodes

# If node NotReady, see "Node Not Ready" scenario above

# Fix node first, then DaemonSet pod should schedule automatically
```

### Cause 4: Insufficient Resources
```bash
# Check DaemonSet resource requests
kubectl get daemonset <ds-name> -o yaml | grep -A 10 "resources:"

# Check node available resources
kubectl describe node <node-name> | grep -A 5 "Allocated resources"

# If node doesn't have resources, either:
# 1. Add more capacity to node
# 2. Reduce DaemonSet resource requests:

kubectl edit daemonset <ds-name> -n <namespace>

# Find spec.template.spec.containers[0].resources
resources:
  requests:
    memory: "64Mi"
    cpu: "50m"
  limits:
    memory: "128Mi"
    cpu: "100m"

# Reduce the values if needed
```

### Cause 5: Pod Crashing After Scheduling
```bash
# Check DaemonSet pod status
kubectl get pods -n <namespace> -l <ds-selector> -o wide

# If Pending after long time, pod won't schedule:
# Use kubectl describe to see events

kubectl get pods -n <namespace> -l <ds-selector> -o jsonpath='{.items[*].metadata.name}' | \
  xargs -I {} kubectl describe pod {} -n <namespace>

# Look for error events

# Check pod logs
kubectl logs -n <namespace> <pod-name>

# If CrashLoopBackOff:
# Fix the issue in DaemonSet spec

kubectl edit daemonset <ds-name> -n <namespace>

# Update image, command, env, etc.
```

## Recovery Process
```bash
# 1. Verify DaemonSet desired vs ready
kubectl get daemonset <ds-name> -n <namespace>

# 2. If mismatch, identify missing node
kubectl get nodes | while read node; do
  if ! kubectl get pod -n <namespace> -l <selector> --field-selector spec.nodeName=$node | grep -q <ds-name>; then
    echo "Missing on: $node"
  fi
done

# 3. Check that node
kubectl describe node <node-name>

# 4. Apply fix (taints, labels, resources)

# 5. Monitor pod schedule
watch 'kubectl get daemonset <ds-name> -n <namespace>'
```

---

## DaemonSet Issue: Slow Rollout

**Symptoms:**
- DaemonSet update takes long time
- Old pods not removed before new ones created
- New pods stuck in Pending

## Diagnosis
```bash
# Check rollout status
kubectl rollout status daemonset/<ds-name> -n <namespace>

# Check for pods being updated
kubectl get pods -n <namespace> -l <ds-selector> -o wide

# Check DaemonSet update strategy
kubectl get daemonset <ds-name> -o yaml | grep -A 5 "updateStrategy"

# Check for pod disruption budgets
kubectl get pdb -n <namespace>
```

## Fix: Adjust Update Strategy
```bash
# Default: RollingUpdate with maxUnavailable=1

# Check current strategy
kubectl get daemonset <ds-name> -o yaml | grep -A 3 "updateStrategy"

# Speed up by increasing maxUnavailable:
kubectl patch daemonset <ds-name> \
  -p '{"spec":{"updateStrategy":{"type":"RollingUpdate","rollingUpdate":{"maxUnavailable":2}}}}'

# Verify update starts
kubectl rollout status daemonset/<ds-name> -n <namespace>

# Monitor pods
watch 'kubectl get pods -n <namespace> -l <selector>'
```

---

## Quick Reference: Workload Issues

| Issue | Command to Check | Common Fix |
|-------|------------------|-----------|
| CronJob not running | `kubectl describe cronjob` | Unsuspend or fix schedule |
| Missed deadline | `kubectl describe job` | Increase startingDeadlineSeconds |
| Jobs pile up | `kubectl get jobs` | Set successfulJobsHistoryLimit |
| DaemonSet incomplete | `kubectl get daemonset` | Add toleration or fix taint |
| Node missing pod | `kubectl describe node` | Check nodeSelector/taints |
| Slow DaemonSet update | `kubectl get pods -w` | Increase maxUnavailable |

---

## CKA Exam Tips

- **CronJob suspend field**: Can disable jobs without deleting them
- **Schedule validation**: Cron format strictly 5 fields (min hour day month weekday)
- **DaemonSet tolerations**: Always needed for master/tainted nodes
- **History limits**: Know difference between successful and failed job retention
- **Deadline matters**: Jobs skip if deadline exceeded before run time
- **Taint vs NodeSelector**: DaemonSet mostly uses tolerations, not selectors
- **Update strategy**: DaemonSet slower by default, may need tuning for large clusters

---

## See Also
- Pod troubleshooting scenarios (for pod-level issues within workloads)
- Deployment troubleshooting (similar update strategy concepts)
- RBAC and ServiceAccount issues (for job permission problems)
