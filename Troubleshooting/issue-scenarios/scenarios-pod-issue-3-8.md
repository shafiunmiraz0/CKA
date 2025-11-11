# Pod Issue Troubleshooting Scenario 3: ImagePullBackOff

## Quick Diagnosis
```bash
kubectl describe pod <pod-name>  # Look for "ImagePullBackOff" and error message
kubectl logs <pod-name> --previous  # Usually no logs (container never started)
```

## Common Causes & Fixes

### Issue 1: Invalid Image Name
```bash
# Diagnostic
kubectl get pod <pod> -o jsonpath='{.spec.containers[0].image}'
# Output: "my-registry.com/myapp:latestt"  (typo!)

# Fix: Correct the image name
kubectl set image pod/<pod> <container>=my-registry.com/myapp:latest
```

### Issue 2: Image Not Found in Registry
```bash
# Diagnostic: Try pulling manually
ssh <node> && docker pull my-registry.com/myapp:v1.0
# Error: manifest not found

# Fix: Ensure image was pushed
docker push my-registry.com/myapp:v1.0

# Then restart pod
kubectl delete pod <pod>
```

### Issue 3: Missing Image Pull Secret
```bash
# Diagnostic
kubectl get pod <pod> -o jsonpath='{.spec.imagePullSecrets}' | jq .
# Empty output!

# Check if secret exists
kubectl get secret <secret-name>
# Error: NotFound

# Fix: Create secret and add to pod
kubectl create secret docker-registry regcred \
  --docker-server=my-registry.com \
  --docker-username=user \
  --docker-password=pass \
  --docker-email=user@example.com

# Update pod to use secret
kubectl patch pod <pod> -p '{"spec":{"imagePullSecrets":[{"name":"regcred"}]}}'
```

### Issue 4: Network Connectivity to Registry
```bash
# Diagnostic: SSH to node and test
ssh <node> && curl https://my-registry.com
# Connection refused

# Fix: Check firewall rules, registry availability
# Then restart pod
kubectl delete pod <pod>
```

### Issue 5: Incorrect Credentials
```bash
# Diagnostic
kubectl describe pod <pod> | grep -i "unauthorized\|forbidden"

# Fix: Recreate secret with correct credentials
kubectl delete secret regcred
kubectl create secret docker-registry regcred \
  --docker-server=my-registry.com \
  --docker-username=correctuser \
  --docker-password=correctpass
```

## YAML Example: Correct Config
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: app
spec:
  imagePullSecrets:  # ✓ Add this for private registry
  - name: regcred
  containers:
  - name: app
    image: my-registry.com/myapp:v1.0  # ✓ Correct registry and tag
```

## Quick Commands
```bash
kubectl describe pod <pod>              # Check error
docker pull <image>                     # Test image pull
kubectl get secret regcred              # Verify secret exists
kubectl delete pod <pod>                # Restart pod
kubectl get pod <pod> --watch           # Watch recovery
```

---

# Pod Issue Troubleshooting Scenario 4: ImagePullBackOff - Advanced

## Issue: Rate Limiting or Quota Exceeded

```bash
# Diagnostic
kubectl describe pod <pod> | grep -i "rate\|quota\|limit"

# Fix: Use image cache or wait for quota reset
kubectl set image pod/<pod> app=<image>:<newtag>
```

## Issue: Repository Requires Authentication But Wrong Secret Type

```bash
# Diagnostic
kubectl get secret regcred -o jsonpath='{.type}'
# Should be: kubernetes.io/dockercfg or kubernetes.io/dockerjson

# Fix: Recreate as proper type
kubectl delete secret regcred
kubectl create secret docker-registry regcred \
  --docker-server=registry.example.com \
  --docker-username=user \
  --docker-password=pass
```

## Full Debugging Script
```bash
#!/bin/bash
POD=$1
NAMESPACE=${2:-default}

echo "=== Pod Status ==="
kubectl describe pod $POD -n $NAMESPACE | grep -A 3 "Status\|Message"

echo "=== Image ==="
kubectl get pod $POD -o jsonpath='{.spec.containers[0].image}' -n $NAMESPACE

echo "=== Image Pull Secrets ==="
kubectl get pod $POD -o jsonpath='{.spec.imagePullSecrets}' -n $NAMESPACE

echo "=== Events ==="
kubectl describe pod $POD -n $NAMESPACE | tail -20
```

---

# Pod Issue Troubleshooting Scenario 5: FailedMount - Volume Issues

## Symptoms
- Pod status: FailedMount or FailedAttachVolume
- Container not starting
- Volume cannot be mounted or attached

## Diagnostic Commands
```bash
kubectl describe pod <pod-name>
kubectl get pvc <pvc-name>
kubectl get pv <pv-name>
```

## Common Issues

### Issue 1: PVC Not Bound
```bash
# Diagnostic
kubectl get pvc my-pvc
# Output: STATUS=Pending

# Check PVC events
kubectl describe pvc my-pvc | grep -i "message\|warning"

# Fix: Ensure StorageClass provisioner is running
kubectl get pods -n kube-system | grep provisioner

# Or create matching PV for static binding
```

### Issue 2: PVC Access Mode Mismatch
```bash
# Pod wants ReadWriteMany but PV only supports ReadWriteOnce
kubectl get pvc my-pvc -o jsonpath='{.spec.accessModes}'
kubectl get pv my-pv -o jsonpath='{.spec.accessModes}'

# Fix: Use different PV or PVC with matching access modes
```

### Issue 3: Wrong Mount Path or Volume Reference
```yaml
# ❌ Wrong: volumeMounts references non-existent volume
spec:
  containers:
  - name: app
    volumeMounts:
    - name: data
      mountPath: /data
  volumes:
  - name: storage    # ❌ Name mismatch!

# ✓ Correct: names match
spec:
  containers:
  - name: app
    volumeMounts:
    - name: data
      mountPath: /data
  volumes:
  - name: data  # ✓ Matches volumeMount name
    persistentVolumeClaim:
      claimName: my-pvc
```

## Fix
```bash
kubectl patch pod <pod> -p '{"spec":{"volumes":[{"name":"data","persistentVolumeClaim":{"claimName":"my-pvc"}}]}}'
```

---

# Pod Issue Troubleshooting Scenario 6: Evicted Pod

## Symptoms
- Pod status: Evicted
- Pod Age: 0s (just happened)
- No restarts visible

## Common Causes
- Node out of memory (OOM)
- Node out of disk space
- PID limit exceeded
- Kubelet eviction threshold exceeded

## Diagnostic Commands
```bash
# Check node conditions
kubectl describe node <node-name>

# Check allocatable resources
kubectl describe node <node-name> | grep Allocatable

# Get kubelet logs
sudo journalctl -u kubelet -n 100 | grep -i evict

# Check pod events
kubectl describe pod <pod-name>
```

## Common Issues

### Issue 1: Node Out of Memory
```bash
# Diagnostic
kubectl describe node <node> | grep "MemoryPressure"
# Output: MemoryPressure=True

# Fix: Scale down other pods or add more nodes
kubectl scale deployment nginx --replicas=0
kubectl delete pod <low-priority-pod>
```

### Issue 2: Node Out of Disk
```bash
# Diagnostic
kubectl describe node <node> | grep "DiskPressure"
# Output: DiskPressure=True

# SSH to node and check
ssh <node> && df -h
# Output: disk mostly full

# Fix: Clean up old images/logs
docker system prune -a
sudo journalctl --vacuum=100M  # Limit journal size
```

## Recovery
```bash
# Delete evicted pod (forces new attempt)
kubectl delete pod <pod-name>

# If caused by node resource issues, fix node first
# Then pod will be created fresh
```

---

# Pod Issue Troubleshooting Scenario 7: Container Timeout/Hung

## Symptoms
- Pod stuck in ContainerCreating
- Pod stuck in Terminating
- Container does not respond
- kubectl exec hangs

## Diagnostic Commands
```bash
kubectl describe pod <pod>
kubectl get pod <pod> -o jsonpath='{.status.conditions}' | jq .
kubectl logs <pod> -f  # Try to stream logs
```

## Common Issues

### Issue 1: Network Plugin Issues
```bash
# Diagnostic
kubectl describe pod <pod> | grep "network plugin"

# Fix: Restart network plugin
kubectl delete pod -n kube-system -l component=kube-proxy --all
kubectl delete pod -n kube-system -l app=weave  # or your CNI

# Wait for recreation
kubectl get pods -n kube-system --watch
```

### Issue 2: Deadlock in Deletion (Finalizers)
```bash
# Diagnostic
kubectl get pod <pod> -o jsonpath='{.metadata.finalizers}' | jq .

# Force delete
kubectl delete pod <pod> --grace-period=0 --force
```

### Issue 3: Kubelet Unresponsive
```bash
# Check kubelet status on node
sudo systemctl status kubelet

# Restart kubelet
sudo systemctl restart kubelet
```

---

# Pod Issue Troubleshooting Scenario 8: OOMKilled

## Symptoms
- Pod status: OOMKilled
- Exit code: 137 (128+9 for SIGKILL)
- Memory exceeded limit
- Container keeps restarting

## Diagnostic Commands
```bash
# Check termination reason
kubectl get pod <pod> -o jsonpath='{.status.containerStatuses[0].lastState.terminated.reason}'

# Check memory usage
kubectl top pods

# Check memory limit
kubectl get pod <pod> -o jsonpath='{.spec.containers[0].resources.limits.memory}'
```

## Fix: Increase Memory Limit
```yaml
# Before (memory limit too low)
resources:
  limits:
    memory: "256Mi"

# After (increased)
resources:
  requests:
    memory: "512Mi"
  limits:
    memory: "1Gi"
```

## Apply Fix
```bash
# For pod directly
kubectl patch pod <pod> -p '{"spec":{"containers":[{"name":"app","resources":{"limits":{"memory":"1Gi"}}}]}}'

# For deployment
kubectl patch deployment <deploy> -p '{"spec":{"template":{"spec":{"containers":[{"name":"app","resources":{"limits":{"memory":"1Gi"}}}]}}}}'

# Verify new pod uses new limits
kubectl delete pod <pod>  # Force recreate from deployment
kubectl get pod <pod> -o jsonpath='{.spec.containers[0].resources.limits.memory}'
```

## Memory Profiling
```bash
# Install metrics-server if not present
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml

# Monitor memory in real-time
watch 'kubectl top pods'

# Find top memory consumers
kubectl top pods --sort-by=memory
```

---

## CKA Tips for Pod Issues 1-8

- **Always start with `kubectl describe pod`** — Shows status, events, and error messages
- **Check logs with `--previous`** — For CrashLoopBackOff pods
- **Node resources matter** — Pending pods need available resources
- **PVC must be bound** — Pod won't schedule if required PVC is Pending  
- **Memory limits are enforced** — OOMKilled is strict; increase limits or optimize app
- **Image pull secrets required** — For private registries
- **Volume mounts must match volumes** — Names and types must align
- **Evicted pods need node fixes first** — Can't reschedule if node has issues

---

## Quick Scenario Reference

| Scenario | Cause | Fix |
|----------|-------|-----|
| CrashLoopBackOff | App error | Check logs --previous, fix app |
| Pending | No resources | Scale down pods or add nodes |
| ImagePullBackOff | Image issue | Fix image name or registry auth |
| FailedMount | PVC/volume issue | Ensure PVC bound, names match |
| Evicted | Node resource exhaustion | Free node resources |
| Stuck ContainerCreating | Network/CNI issue | Restart network plugin |
| OOMKilled | Memory exceeded | Increase memory limit |
| Terminating stuck | Finalizer issue | Force delete with --grace-period=0 |
