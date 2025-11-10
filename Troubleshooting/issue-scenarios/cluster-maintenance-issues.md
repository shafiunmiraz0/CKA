# Cluster Maintenance Troubleshooting Scenarios

## Common Maintenance Issues

### 1. Node Maintenance Issues
**Symptoms:**
- Node needs maintenance/updates
- Workload disruption during maintenance
- Pod eviction problems

**Debugging Steps:**
```bash
# Check node status
kubectl get nodes
kubectl describe node <node-name>

# Safe node drain
kubectl drain <node-name> --ignore-daemonsets --delete-emptydir-data

# Check pod eviction status
kubectl get pods --all-namespaces -o wide | grep <node-name>
```

### 2. Resource Management Issues
**Symptoms:**
- Node pressure conditions
- Resource quota violations
- LimitRange conflicts

**Debugging Steps:**
```bash
# Check resource quotas
kubectl get resourcequota --all-namespaces
kubectl describe resourcequota <quota-name> -n <namespace>

# Verify limit ranges
kubectl get limitrange --all-namespaces
kubectl describe limitrange <limitrange-name> -n <namespace>

# Check resource usage
kubectl top nodes
kubectl top pods --all-namespaces
```

### 3. System Upgrade Issues
**Symptoms:**
- OS updates needed
- Runtime updates required
- Network plugin updates

**Debugging Steps:**
```bash
# Check OS status
uname -a
cat /etc/os-release

# Verify container runtime
crictl info
docker info  # if using docker

# Check CNI status
kubectl get pods -n kube-system -l k8s-app=calico-node  # for Calico
```

## Maintenance Procedures

### 1. Safe Node Maintenance
```bash
# 1. Mark node unschedulable
kubectl cordon <node-name>

# 2. Drain workloads
kubectl drain <node-name> --ignore-daemonsets --delete-emptydir-data

# 3. Perform maintenance
apt-get update && apt-get upgrade -y

# 4. Return node to service
kubectl uncordon <node-name>
```

### 2. Resource Quota Management
```yaml
# Example ResourceQuota
apiVersion: v1
kind: ResourceQuota
metadata:
  name: compute-quota
  namespace: development
spec:
  hard:
    requests.cpu: "4"
    requests.memory: 4Gi
    limits.cpu: "8"
    limits.memory: 8Gi
    pods: "10"
```

### 3. LimitRange Configuration
```yaml
# Example LimitRange
apiVersion: v1
kind: LimitRange
metadata:
  name: mem-limit-range
  namespace: development
spec:
  limits:
  - default:
      memory: 512Mi
      cpu: 500m
    defaultRequest:
      memory: 256Mi
      cpu: 200m
    type: Container
```

## Quick Reference Commands

```bash
# Node Management
kubectl cordon <node-name>
kubectl drain <node-name> --ignore-daemonsets
kubectl uncordon <node-name>

# Resource Management
kubectl top nodes
kubectl top pods --all-namespaces
kubectl get resourcequota --all-namespaces
kubectl get limitrange --all-namespaces

# System Updates
apt-get update
apt-get upgrade -y
systemctl restart kubelet
```

## Best Practices

### 1. Pod Disruption Budget
```yaml
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: app-pdb
spec:
  minAvailable: 2
  selector:
    matchLabels:
      app: critical-app
```

### 2. Node Maintenance Script
```bash
#!/bin/bash
NODE=$1

# Check if node exists
if ! kubectl get node $NODE > /dev/null 2>&1; then
    echo "Node $NODE not found"
    exit 1
fi

# Cordon node
echo "Cordoning node $NODE..."
kubectl cordon $NODE

# Drain node
echo "Draining node $NODE..."
kubectl drain $NODE --ignore-daemonsets --delete-emptydir-data

# Wait for pods to drain
echo "Waiting for pods to drain..."
while kubectl get pods --all-namespaces -o wide | grep $NODE | grep -v Completed; do
    sleep 5
done

echo "Node $NODE ready for maintenance"
```

### 3. Resource Monitoring
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: resource-monitor
spec:
  containers:
  - name: monitor
    image: k8s.gcr.io/node-problem-detector:v0.8.7
    resources:
      limits:
        cpu: 100m
        memory: 100Mi
      requests:
        cpu: 50m
        memory: 50Mi
    volumeMounts:
    - name: log
      mountPath: /var/log
  volumes:
  - name: log
    hostPath:
      path: /var/log
```