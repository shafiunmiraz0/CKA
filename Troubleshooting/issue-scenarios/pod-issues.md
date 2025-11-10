# Pod Troubleshooting Scenarios

## Common Pod Issues

### 1. Pod in Pending State
**Symptoms:**
- Pod stays in `Pending` state
- No container started

**Debugging Steps:**
```bash
# Check pod status and events
kubectl describe pod <pod-name>

# Check node resources
kubectl describe nodes | grep -A 5 "Allocated resources"

# Check if pod scheduling is affected by taints
kubectl get nodes -o custom-columns=NAME:.metadata.name,TAINTS:.spec.taints
```

**Common Causes:**
- Insufficient resources (CPU/Memory)
- Node selector/affinity rules not matched
- PVC not bound
- Node taints preventing scheduling

### 2. Pod in CrashLoopBackOff
**Symptoms:**
- Pod status shows `CrashLoopBackOff`
- Container repeatedly starts and crashes

**Debugging Steps:**
```bash
# Check pod logs
kubectl logs <pod-name> --previous
kubectl describe pod <pod-name>

# Check container exit code
kubectl get pod <pod-name> -o jsonpath='{.status.containerStatuses[0].lastState.terminated.exitCode}'
```

**Common Causes:**
- Application error
- Invalid command or arguments
- Missing configuration or secrets
- Resource limits too low

### 3. Pod in ImagePullBackOff
**Symptoms:**
- Pod status shows `ImagePullBackOff`
- Container image cannot be pulled

**Debugging Steps:**
```bash
# Check pod events
kubectl describe pod <pod-name>

# Verify image pull secret
kubectl get secrets

# Check if image exists and is accessible
docker pull <image-name>  # On worker node
```

**Common Causes:**
- Invalid image name
- Missing or invalid image pull secrets
- Image not found in registry
- Network connectivity issues

### 4. Pod Network Issues
**Symptoms:**
- Services unreachable
- DNS resolution failures

**Debugging Steps:**
```bash
# Deploy network debugging pod
kubectl run debug --image=busybox --rm -it -- sh

# Inside debug pod:
wget -O- <service-name>.<namespace>.svc.cluster.local
nslookup <service-name>
ping <pod-ip>
```

**Example Debug Pod YAML:**
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: network-debug
spec:
  containers:
  - name: network-debug
    image: nicolaka/netshoot
    command:
      - sleep
      - "3600"
```

### 5. Pod Resource Issues
**Symptoms:**
- OOMKilled status
- Container termination due to resource limits

**Debugging Steps:**
```bash
# Check resource usage
kubectl top pod <pod-name>

# View resource limits and requests
kubectl describe pod <pod-name> | grep -A 3 Requests

# Check node resource allocation
kubectl describe node <node-name>
```

**Example Resource Configuration:**
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: resource-debug
spec:
  containers:
  - name: app
    image: nginx
    resources:
      requests:
        memory: "64Mi"
        cpu: "250m"
      limits:
        memory: "128Mi"
        cpu: "500m"
```

## Quick Reference Commands

```bash
# Get pod status
kubectl get pod <pod-name> -o wide

# Get pod logs
kubectl logs <pod-name> --previous

# Get pod events
kubectl get events --field-selector involvedObject.name=<pod-name>

# Execute command in pod
kubectl exec -it <pod-name> -- /bin/sh

# Check pod configuration
kubectl get pod <pod-name> -o yaml

# Force delete a stuck pod
kubectl delete pod <pod-name> --force --grace-period=0
```