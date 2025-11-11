# Deployment Issues Troubleshooting - Comprehensive Scenarios

## Deployment Issue 1: Pods Not Running

**Symptoms:**
- Deployment shows `Desired: 3, Current: 3, Updated: 3, Available: 0`
- Pods are Pending or Crashing
- Replicas not coming up
- Deployment age increasing but pods never become Ready

## Diagnostic Steps
```bash
# Check deployment status
kubectl describe deployment <deploy-name>

# Check replica set status
kubectl get replicaset -l app=<label>

# Check pod status
kubectl get pods -l app=<label>

# Check pod logs
kubectl logs -l app=<label> --all-containers=true

# Check events
kubectl get events --sort-by='.lastTimestamp'
```

## Common Causes & Fixes

### Cause 1: Pods in CrashLoopBackOff
```bash
# Diagnostic
kubectl get pods -l app=<label>
# Shows: CrashLoopBackOff

# Check logs
kubectl logs <pod> --previous

# Fix: Resolve application issue (see Pod Issue Scenario 1)
```

### Cause 2: Pods Pending (Resource Issue)
```bash
# Diagnostic
kubectl describe deployment <deploy> | grep "Desired\|Current"

# Check why pods pending
kubectl describe pod <pod> | grep -i "failedscheduling"

# Fix: Scale down other deployments or add resources
```

### Cause 3: ReadinessProbe Failing
```bash
# Check pod events
kubectl describe pod <pod> | grep -i "readiness\|liveness"

# Check readiness probe config
kubectl get pod <pod> -o jsonpath='{.spec.containers[0].readinessProbe}' | jq .

# Fix: Update probe or fix application to respond correctly
kubectl patch deployment <deploy> -p '{"spec":{"template":{"spec":{"containers":[{"name":"app","readinessProbe":{"httpGet":{"path":"/health","port":8080},"initialDelaySeconds":10}}]}}}}'
```

---

## Deployment Issue 2: Deployment Not Updating (Not Up-to-Date)

**Symptoms:**
- Shows `Desired: 3, Current: 3, Updated: 0, Available: 3`
- Deployment image updated but pods still running old image
- New ReplicaSet created but old pods not replaced

## Diagnostic Steps
```bash
# Check deployment status
kubectl describe deployment <deploy>

# Check ReplicaSets
kubectl get replicaset -l app=<label> -o wide

# Check which image is running
kubectl get pods -o jsonpath='{.items[0].spec.containers[0].image}'

# Check deployment image
kubectl get deployment <deploy> -o jsonpath='{.spec.template.spec.containers[0].image}'
```

## Common Causes & Fixes

### Issue 1: Image Tag Not Changing
```bash
# Problem: Using "latest" tag, but not pulling new image
kubectl set image deployment/<deploy> app=myimage:v1.1 --record

# Verify new ReplicaSet created
kubectl get replicaset -l app=<label> -o wide

# Or use new tag strategy
kubectl patch deployment <deploy> -p '{"spec":{"template":{"spec":{"containers":[{"name":"app","image":"myimage:v1.2"}]}}}}'
```

### Issue 2: MaxSurge/MaxUnavailable Too Strict
```yaml
# Problem: RollingUpdate settings too restrictive
# If maxSurge=0 and maxUnavailable=0, no pods can be updated

# Fix:
strategy:
  type: RollingUpdate
  rollingUpdate:
    maxSurge: 1           # Allow 1 extra pod during update
    maxUnavailable: 1     # Allow 1 pod to be unavailable
```

### Issue 3: New Pods Failing to Start
```bash
# Diagnostic
kubectl get replicaset -l app=<label> -o wide

# Check new ReplicaSet events
kubectl describe replicaset <new-rs-name>

# Check pod status in new ReplicaSet
kubectl get pods -l controller-revision-hash=<hash>

# Fix: Same as Deployment Issue 1 (pods not running)
```

---

## Deployment Issue 3: Stuck Rollout

**Symptoms:**
- Deployment status shows `Conditions: Progressing: False`
- Stuck in middle of update
- Doesn't progress forward or back

## Diagnostic Steps
```bash
# Check deployment conditions
kubectl get deployment <deploy> -o jsonpath='{.status.conditions}' | jq .

# Check rollout status
kubectl rollout status deployment/<deploy>

# Check recent events
kubectl describe deployment <deploy> | tail -30

# Check if pods are pending
kubectl get pods -l app=<label>
```

## Common Causes & Fixes

### Issue 1: Readiness Probe Timeout
```bash
# Pod starts but readiness probe keeps failing
kubectl describe pod <pod> | grep "Readiness probe failed"

# Check pod readiness
kubectl get pod <pod> -o jsonpath='{.status.conditions[?(@.type=="Ready")]}' | jq .

# Fix: Increase initialDelaySeconds or fix application
kubectl patch deployment <deploy> -p '{"spec":{"template":{"spec":{"containers":[{"name":"app","readinessProbe":{"initialDelaySeconds":30,"timeoutSeconds":5}}]}}}}'

# Or restart rollout
kubectl rollout restart deployment/<deploy>
```

### Issue 2: Liveness Probe Killing Pods
```bash
# Pods restart infinitely due to liveness probe
kubectl describe pod <pod> | grep "Liveness probe failed"

# Check liveness configuration
kubectl get deployment <deploy> -o jsonpath='{.spec.template.spec.containers[0].livenessProbe}' | jq .

# Fix: Relax probe or fix application
kubectl patch deployment <deploy> -p '{"spec":{"template":{"spec":{"containers":[{"name":"app","livenessProbe":{"periodSeconds":20,"failureThreshold":5}}]}}}}'
```

### Issue 3: Resource Constraints
```bash
# New pods can't start due to insufficient resources
kubectl describe deployment <deploy> | grep -i "insufficient"

# Fix: Free resources or reduce pod resource requests
kubectl scale deployment <deploy> --replicas=1  # Reduce replicas
# Or fix resource requests
```

---

## Deployment Issue 4: Rollback/Revision Issues

**Symptoms:**
- Rollback not working
- Wrong revision applied
- Cannot see rollout history
- Stuck in broken state

## Diagnostic Steps
```bash
# Check rollout history
kubectl rollout history deployment/<deploy>

# See details of specific revision
kubectl rollout history deployment/<deploy> --revision=2

# Check current image
kubectl get deployment <deploy> -o jsonpath='{.spec.template.spec.containers[0].image}'

# Check all ReplicaSets
kubectl get replicaset -l app=<label> -o wide
```

## Common Causes & Fixes

### Issue 1: Can't Rollback (History Lost)
```bash
# Problem: No revision history or limited history
# Fix: Ensure .spec.revisionHistoryLimit is set

kubectl patch deployment <deploy> -p '{"spec":{"revisionHistoryLimit":10}}'

# Then make a change to create new revision
kubectl set image deployment/<deploy> app=myimage:v1.2
```

### Issue 2: Wrong Revision Applied
```bash
# Check available revisions
kubectl rollout history deployment/<deploy>

# Rollback to specific revision
kubectl rollout undo deployment/<deploy> --to-revision=1

# Verify rollback
kubectl rollout status deployment/<deploy>
```

### Issue 3: Rollback Fails
```bash
# Diagnostic
kubectl rollout history deployment/<deploy>

# Force rollback by patching deployment directly
kubectl patch deployment <deploy> -p '{"spec":{"template":{"spec":{"containers":[{"name":"app","image":"myimage:v1.0"}]}}}}'

# Monitor rollback
kubectl get deployment <deploy> --watch
kubectl describe deployment <deploy>
```

---

## Deployment Issue - Deployment Not UP-TO-DATE (Deep Dive)

**Symptoms:**
- Status shows `Desired: 3, Current: 3, Updated: 0, Available: 3`
- All pods running, but none are up-to-date with new spec
- Looks like update failed silently

## Root Cause Analysis

### Scenario A: Image Hasn't Changed
```bash
# Check what changed
kubectl get deployment <deploy> -o jsonpath='{.spec.template.spec.containers[0].image}'

# If using "latest" tag and Kubernetes image pull policy
kubectl get deployment <deploy> -o jsonpath='{.spec.template.spec.containers[0].imagePullPolicy}'

# Problem: imagePullPolicy may be "IfNotPresent" instead of "Always"
# So "latest" tag doesn't force new image pull

# Fix: Explicitly change tag or set imagePullPolicy
kubectl set image deployment/<deploy> app=myimage:v1.2 --record
# OR
kubectl patch deployment <deploy> -p '{"spec":{"template":{"spec":{"containers":[{"name":"app","imagePullPolicy":"Always"}]}}}}'
```

### Scenario B: Spec Change Wasn't Detected
```bash
# Check deployment annotations for change
kubectl get deployment <deploy> -o jsonpath='{.spec.template.metadata.annotations}' | jq .

# Try forcing update by changing annotation
kubectl patch deployment <deploy> -p '{"spec":{"template":{"metadata":{"annotations":{"updated":"'$(date +%s)'"}}}}}' 

# This triggers new ReplicaSet creation
```

### Scenario C: RollingUpdate Paused
```bash
# Check if deployment is paused
kubectl rollout status deployment/<deploy>
# If says "paused"...

# Resume the deployment
kubectl rollout resume deployment/<deploy>
```

---

## Full Debugging Workflow

```bash
#!/bin/bash
DEPLOY=$1
NS=${2:-default}

echo "=== Deployment Status ==="
kubectl describe deployment $DEPLOY -n $NS | head -20

echo "=== Desired vs Current ==="
kubectl get deployment $DEPLOY -n $NS -o custom-columns=DESIRED:.spec.replicas,CURRENT:.status.replicas,UPDATED:.status.updatedReplicas,AVAILABLE:.status.availableReplicas

echo "=== ReplicaSets ==="
kubectl get replicaset -l app=$(kubectl get deployment $DEPLOY -o jsonpath='{.spec.selector.matchLabels.app}') -n $NS -o wide

echo "=== Pods ==="
kubectl get pods -l app=$(kubectl get deployment $DEPLOY -o jsonpath='{.spec.selector.matchLabels.app}') -n $NS -o wide

echo "=== Image Running ==="
kubectl get pods -l app=$(kubectl get deployment $DEPLOY -o jsonpath='{.spec.selector.matchLabels.app}') -n $NS -o jsonpath='{.items[0].spec.containers[0].image}'

echo "=== Deployment Image ==="
kubectl get deployment $DEPLOY -n $NS -o jsonpath='{.spec.template.spec.containers[0].image}'

echo "=== Rollout Status ==="
kubectl rollout status deployment/$DEPLOY -n $NS

echo "=== Recent Events ==="
kubectl get events -n $NS --sort-by='.lastTimestamp' | tail -20
```

---

## Common Deployment Fixes Reference

| Issue | Fix Command |
|-------|-----|
| Update image | `kubectl set image deployment/<d> app=<img>` |
| Restart pods | `kubectl rollout restart deployment/<d>` |
| Scale replicas | `kubectl scale deployment/<d> --replicas=N` |
| Rollback version | `kubectl rollout undo deployment/<d>` |
| Check history | `kubectl rollout history deployment/<d>` |
| Pause deployment | `kubectl rollout pause deployment/<d>` |
| Resume deployment | `kubectl rollout resume deployment/<d>` |
| Patch spec | `kubectl patch deployment/<d> -p '...'` |
| Check status | `kubectl rollout status deployment/<d>` |
| Get conditions | `kubectl get deployment/<d> -o json \| jq .status.conditions` |

---

## CKA Tips

- **Desired vs Current**: If numbers don't match, check pod logs
- **Updated field critical**: Shows how many pods have new spec
- **ReadinessProbe blocks updates**: Stuck on readiness check
- **Image policy matters**: "IfNotPresent" won't pull "latest" tag update
- **Revision history**: Set `revisionHistoryLimit` for rollback capability
- **Rollout status**: `kubectl rollout status` shows if stuck
- **Quick restart**: `kubectl rollout restart` cycles all pods safely

---

## See Also
- Deployment YAML template
- RollingUpdate strategy configuration
- ReadinessProbe and LivenessProbe setup
- Pod troubleshooting scenarios 1-8
