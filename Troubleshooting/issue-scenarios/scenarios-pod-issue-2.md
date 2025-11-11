# Pod Issue Troubleshooting Scenario 2

## Issue: Pod Stuck in Pending State

**Symptoms:**
- Pod status shows `Pending`
- No container has started
- Pod remains stuck indefinitely
- Not scheduled to any node

**Root Causes:**
- Insufficient cluster resources (CPU/Memory)
- Node selector labels don't match any node
- Affinity rules cannot be satisfied
- Taints on nodes block scheduling
- PersistentVolumeClaim not bound
- Image registry secret missing
- Scheduler issues

---

## Step 1: Initial Diagnosis

### Check Pod and Scheduling Status
```bash
# Get pod status
kubectl get pod <pod-name> -n <namespace>

# Check detailed pod info and events
kubectl describe pod <pod-name> -n <namespace>

# Check which node it's scheduled to (should be empty for Pending)
kubectl get pod <pod-name> -o jsonpath='{.spec.nodeName}' -n <namespace>

# Check pod events specifically
kubectl describe pod <pod-name> -n <namespace> | tail -20
```

### Expected Output
```
NAME          READY   STATUS    RESTARTS   AGE
pending-pod   0/1     Pending   0          5m

# Events section:
Type     Reason            Age   From                 Message
----     ------            ---   ----                 -------
Warning  FailedScheduling  5m    default-scheduler    0/3 nodes are available:
                                                       1 Insufficient memory,
                                                       1 node has label 'env!=prod',
                                                       1 Insufficient CPU.
```

---

## Step 2: Check Resource Availability

### Verify Cluster Resources
```bash
# Get node capacity and allocatable resources
kubectl get nodes -o custom-columns=NAME:.metadata.name,CPU:.status.capacity.cpu,MEMORY:.status.capacity.memory,CPU_ALLOC:.status.allocatable.cpu,MEMORY_ALLOC:.status.allocatable.memory

# Get detailed node resource usage
kubectl describe nodes | grep -A 5 "Allocated resources"

# Check top nodes (requires metrics-server)
kubectl top nodes

# Get node details for specific node
kubectl describe node <node-name>
```

### Example Output Showing Resource Exhaustion
```
NAME              CPU    MEMORY     CPU_ALLOC   MEMORY_ALLOC
master            4      8Gi        4           8Gi
worker-node-1     4      8Gi        2000m       4Gi      # Low on memory!
worker-node-2     4      8Gi        3500m       7Gi      # Low on both!
```

### Check Pod Resource Request
```bash
# Get pod resource requests
kubectl get pod <pod-name> -o jsonpath='{.spec.containers[0].resources.requests}' -n <namespace> | jq .

# Get pod resource limits
kubectl get pod <pod-name> -o jsonpath='{.spec.containers[0].resources.limits}' -n <namespace> | jq .

# Example output:
# {
#   "cpu": "2",
#   "memory": "4Gi"
# }
```

### Common Issues: Insufficient Resources

**Scenario 1: Pod requests 2 CPU but only 1.5 CPU available**
```bash
# Pod requests:
kubectl get pod <pod-name> -o jsonpath='{.spec.containers[0].resources.requests}' | jq .
# Output: {"cpu":"2","memory":"2Gi"}

# Available on nodes:
kubectl describe node worker-node-1 | grep "Allocatable\|Allocated"
# Shows: Allocatable CPU: 4, Allocated CPU: 2.5 = only 1.5 free
# Pod requests 2, but only 1.5 available → Pending!

# Solution: Create node, or reduce pod resource request
kubectl scale deployment <deployment> --replicas=0  # Free up resources
```

---

## Step 3: Check Node Selectors and Affinity

### Verify Node Selector
```bash
# Get pod node selector
kubectl get pod <pod-name> -o jsonpath='{.spec.nodeSelector}' -n <namespace> | jq .

# Get available node labels
kubectl get nodes --show-labels

# Check if selector matches any node
kubectl get nodes --show-labels | grep <label-key>=<label-value>
```

### Common Node Selector Issues

**Issue: Node Selector Mismatch**
```bash
# Pod specifies: nodeSelector: env: prod
# But available nodes labeled: env: dev

# Diagnostic:
kubectl get nodes --show-labels | grep env=

# Fix: Either relabel node or update pod selector
kubectl label nodes <node-name> env=prod --overwrite

# Verify:
kubectl get nodes --show-labels | grep <node-name>
```

### Check Pod Affinity Rules
```bash
# Get affinity rules
kubectl get pod <pod-name> -o jsonpath='{.spec.affinity}' -n <namespace> | jq .

# Check if affinity can be satisfied
# Example: Pod requires pod affinity to "app=database" pod, but no such pod exists
kubectl get pods -A -l app=database

# If output is empty, affinity cannot be satisfied
```

---

## Step 4: Check Node Taints

### View Node Taints
```bash
# Get all nodes and their taints
kubectl get nodes -o custom-columns=NAME:.metadata.name,TAINTS:.spec.taints

# Get detailed taints for specific node
kubectl describe node <node-name> | grep Taints

# Example output showing taints:
# Taints:  node-role.kubernetes.io/master=:NoSchedule
#          key1=value1:NoExecute
```

### Common Taint Issues

**Issue: Pod cannot tolerate node taint**
```bash
# Node has taint: key=value:NoSchedule
# Pod has no toleration → cannot schedule

# Check pod tolerations:
kubectl get pod <pod-name> -o jsonpath='{.spec.tolerations}' -n <namespace> | jq .

# If empty, pod has no tolerations

# Fix: Add toleration to pod:
kubectl patch pod <pod-name> -p '{"spec":{"tolerations":[{"key":"key","operator":"Equal","value":"value","effect":"NoSchedule"}]}}'
```

---

## Step 5: Check Image and Secret

### Verify Image Availability
```bash
# Get pod image
kubectl get pod <pod-name> -o jsonpath='{.spec.containers[0].image}' -n <namespace>

# Try to pull image manually (on node)
# SSH to node, then:
docker pull <image-name>
# or
crictl pull <image-name>
```

### Check Image Pull Secrets
```bash
# Get pod's imagePullSecrets
kubectl get pod <pod-name> -o jsonpath='{.spec.imagePullSecrets}' -n <namespace> | jq .

# If using private registry, verify secret exists
kubectl get secret <secret-name> -n <namespace>

# Verify secret is correct type
kubectl get secret <secret-name> -o jsonpath='{.type}'
# Should be: kubernetes.io/dockercfg or kubernetes.io/dockerjson
```

---

## Step 6: Check PersistentVolumeClaim

### Verify PVC Status
```bash
# Get pod volumes
kubectl get pod <pod-name> -o jsonpath='{.spec.volumes}' -n <namespace> | jq .

# Check if any PVC is used
kubectl get pod <pod-name> -o jsonpath='{.spec.volumes[*].persistentVolumeClaim.claimName}' -n <namespace>

# Check PVC status
kubectl get pvc <pvc-name> -n <namespace>

# If PVC is Pending, pod cannot schedule
kubectl describe pvc <pvc-name> -n <namespace>
```

### Common PVC Issues

**Issue: PVC Pending**
```
NAME        STATUS    VOLUME   CAPACITY   ACCESS MODES   STORAGECLASS   AGE
app-pvc     Pending                                      standard       5m
```

This blocks pod scheduling. Fix:
```bash
# Check StorageClass exists
kubectl get sc

# If StorageClass missing or provisioner down, fix and PVC will bind
# Then pod will schedule
kubectl get pod <pod-name> --watch  # Watch it transition to Running
```

---

## Step 7: Scheduler Status

### Verify Scheduler is Running
```bash
# Check if scheduler pods exist
kubectl get pods -n kube-system -l component=kube-scheduler

# Check scheduler logs
kubectl logs -n kube-system -l component=kube-scheduler --tail=50

# If no logs or pod not running:
sudo systemctl status kube-scheduler  # On master node
sudo journalctl -u kube-scheduler -n 50
```

---

## Step 8: Common Fixes

### Fix 1: Free Up Resources
```bash
# Remove less critical deployments to free resources
kubectl delete deployment <non-critical-deployment>

# Or scale down existing deployments
kubectl scale deployment <deployment> --replicas=1

# Watch pending pod for scheduling
kubectl get pod <pod-name> --watch
```

### Fix 2: Add More Nodes
```bash
# Add new node to cluster (depends on your infrastructure)
# Then verify it's available:
kubectl get nodes

# Pending pod should now be scheduled
```

### Fix 3: Reduce Pod Resource Requests
```yaml
# Before (requesting too much):
resources:
  requests:
    cpu: "2"
    memory: "4Gi"

# After (request less):
resources:
  requests:
    cpu: "500m"
    memory: "512Mi"
  limits:
    cpu: "1"
    memory: "1Gi"
```

### Fix 4: Fix Node Selector
```bash
# Option 1: Add label to node
kubectl label nodes <node-name> env=prod

# Option 2: Remove node selector from pod
kubectl patch pod <pod-name> -p '{"spec":{"nodeSelector":null}}'

# Verify pod now schedules
kubectl get pod <pod-name>
```

### Fix 5: Add Toleration
```yaml
# Add toleration for node taint:
apiVersion: v1
kind: Pod
metadata:
  name: app
spec:
  containers:
  - name: app
    image: nginx
  tolerations:
  - key: "key"
    operator: "Equal"
    value: "value"
    effect: "NoSchedule"
```

---

## Full Test Scenario

### Scenario: Pod Pending Due to Insufficient Resources

**Initial State:**
```bash
# Check nodes
kubectl get nodes
# NAME              STATUS   ROLES     CPU    MEMORY
# master            Ready    master    4      8Gi
# worker-node-1     Ready    worker    4      8Gi   (only 1Gi free)
# worker-node-2     Ready    worker    4      8Gi   (only 2Gi free)

# Try to create pod requesting 4Gi memory
kubectl apply -f - << 'EOF'
apiVersion: v1
kind: Pod
metadata:
  name: memory-hog
spec:
  containers:
  - name: app
    image: nginx
    resources:
      requests:
        memory: "4Gi"
        cpu: "2"
EOF

# Check pod status
kubectl describe pod memory-hog
# Shows: FailedScheduling - 0/3 nodes available, all have insufficient memory
```

**Diagnostic Steps:**
```bash
# Step 1: Check node resources
kubectl top nodes

# Step 2: Check pod request
kubectl get pod memory-hog -o jsonpath='{.spec.containers[0].resources.requests}' | jq .
# Output: {"cpu":"2","memory":"4Gi"}

# Step 3: Check events
kubectl describe pod memory-hog | tail -20
```

**Resolution:**
```bash
# Option 1: Scale down existing pods to free memory
kubectl scale deployment nginx-deployment --replicas=1

# Option 2: Reduce pod resource request
kubectl delete pod memory-hog
kubectl apply -f - << 'EOF'
apiVersion: v1
kind: Pod
metadata:
  name: memory-hog
spec:
  containers:
  - name: app
    image: nginx
    resources:
      requests:
        memory: "1Gi"    # ✓ Reduced
        cpu: "500m"      # ✓ Reduced
EOF

# Verify pod now schedules
kubectl get pod memory-hog
# Output: memory-hog   1/1     Running   0          10s
```

---

## CKA Exam Tips

- **Pending = Scheduling Failed**: Always check `kubectl describe pod` for FailedScheduling
- **Resource math**: Pod requests + already allocated = Must be ≤ node capacity
- **Scheduler logs**: `kubectl logs -n kube-system -l component=kube-scheduler` show why pod not scheduled
- **Node labels matter**: Node selector and affinity must match available nodes
- **Taints block scheduling**: Pod needs matching tolerations
- **PVC blocks pod**: Pod won't schedule if required PVC is Pending
- **Quick fix**: Often just need to scale down other deployments or reduce resource request

---

## Quick Reference

| Check | Command |
|-------|---------|
| Pod status | `kubectl describe pod <pod>` |
| Node resources | `kubectl top nodes` |
| Node allocatable | `kubectl describe nodes \| grep Allocatable` |
| Pod request | `kubectl get pod <pod> -o jsonpath='{.spec.containers[0].resources.requests}'` |
| Node labels | `kubectl get nodes --show-labels` |
| Node taints | `kubectl get nodes -o custom-columns=TAINTS:.spec.taints` |
| PVC status | `kubectl get pvc <pvc>` |
| Scheduler status | `kubectl logs -n kube-system -l component=kube-scheduler` |

---

## See Also
- Pod issue scenarios 1, 3-8
- Resource management and limits
- Node selectors and affinity
- Taints and tolerations
