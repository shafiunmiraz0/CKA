# Resource Management and Advanced Scheduling

## 1. Resource Quotas and Limits

### Namespace Resource Quota
```yaml
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
    configmaps: "10"
    persistentvolumeclaims: "4"
    services.nodeports: "2"
    services.loadbalancers: "1"
```

### LimitRange for Containers
```yaml
apiVersion: v1
kind: LimitRange
metadata:
  name: mem-limit-range
spec:
  limits:
  - default:
      memory: "512Mi"
      cpu: "500m"
    defaultRequest:
      memory: "256Mi"
      cpu: "200m"
    type: Container
```

## 2. Advanced Scheduling

### Node Affinity
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: with-node-affinity
spec:
  affinity:
    nodeAffinity:
      requiredDuringSchedulingIgnoredDuringExecution:
        nodeSelectorTerms:
        - matchExpressions:
          - key: kubernetes.io/e2e-az-name
            operator: In
            values:
            - e2e-az1
            - e2e-az2
      preferredDuringSchedulingIgnoredDuringExecution:
      - weight: 1
        preference:
          matchExpressions:
          - key: disk-type
            operator: In
            values:
            - ssd
```

### Pod Affinity/Anti-Affinity
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: with-pod-affinity
spec:
  affinity:
    podAffinity:
      requiredDuringSchedulingIgnoredDuringExecution:
      - labelSelector:
          matchExpressions:
          - key: app
            operator: In
            values:
            - cache
        topologyKey: "kubernetes.io/hostname"
    podAntiAffinity:
      preferredDuringSchedulingIgnoredDuringExecution:
      - weight: 100
        podAffinityTerm:
          labelSelector:
            matchExpressions:
            - key: app
              operator: In
              values:
              - web
          topologyKey: "kubernetes.io/hostname"
```

### Taints and Tolerations
```yaml
# Taint a node
apiVersion: v1
kind: Node
metadata:
  name: node1
spec:
  taints:
  - key: "key"
    value: "value"
    effect: "NoSchedule"

# Pod with toleration
apiVersion: v1
kind: Pod
metadata:
  name: nginx-toleration
spec:
  containers:
  - name: nginx
    image: nginx
  tolerations:
  - key: "key"
    operator: "Equal"
    value: "value"
    effect: "NoSchedule"
```

## 3. Pod Priority and Preemption

### Priority Class
```yaml
apiVersion: scheduling.k8s.io/v1
kind: PriorityClass
metadata:
  name: high-priority
value: 1000000
globalDefault: false
description: "High priority pods"
```

### Pod with Priority
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: nginx-priority
spec:
  priorityClassName: high-priority
  containers:
  - name: nginx
    image: nginx
```

## 4. Advanced Pod Placement

### Pod Topology Spread Constraints
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: topology-spread-pod
spec:
  topologySpreadConstraints:
  - maxSkew: 1
    topologyKey: topology.kubernetes.io/zone
    whenUnsatisfiable: DoNotSchedule
    labelSelector:
      matchLabels:
        app: web
  containers:
  - name: nginx
    image: nginx
```

### Pod Disruption Budget
```yaml
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: app-pdb
spec:
  minAvailable: 2
  selector:
    matchLabels:
      app: web
```

## Commands Reference

### Resource Management
```bash
# Resource Quota
kubectl create quota dev-quota --hard=cpu=2,memory=4Gi
kubectl describe quota -n <namespace>

# LimitRange
kubectl create -f limit-range.yaml
kubectl get limitrange
kubectl describe limitrange <name>
```

### Node Management
```bash
# Taint management
kubectl taint nodes node1 key=value:NoSchedule
kubectl taint nodes node1 key:NoSchedule-

# Node labels
kubectl label nodes <node-name> disk-type=ssd
kubectl get nodes --show-labels
```

### Priority and Preemption
```bash
# Priority Class
kubectl get priorityclass
kubectl describe priorityclass high-priority

# Check pod priority
kubectl get pod <pod-name> -o yaml | grep priority
```

## Troubleshooting Guide

### 1. Scheduling Issues
```bash
# Check scheduler logs
kubectl logs -n kube-system kube-scheduler-<master-node>

# Check pod status
kubectl get pod <pod-name> -o yaml | grep message
kubectl describe pod <pod-name>

# Node capacity and allocation
kubectl describe node <node-name> | grep -A 5 Allocated
```

### 2. Resource Issues
```bash
# Check resource usage
kubectl top nodes
kubectl top pods

# Resource quota usage
kubectl describe quota
kubectl describe resourcequota <quota-name> -n <namespace>
```

### 3. Pod Placement
```bash
# Check node affinity
kubectl get pod <pod-name> -o yaml | grep -A 10 affinity

# Check taints and tolerations
kubectl get nodes -o custom-columns=NAME:.metadata.name,TAINTS:.spec.taints
kubectl describe pod <pod-name> | grep -A 5 Tolerations
```

## Best Practices

### 1. Resource Management
- Set appropriate resource requests and limits
- Use ResourceQuotas for namespace resource control
- Implement LimitRanges for default values
- Monitor resource usage regularly

### 2. Scheduling
- Use node affinity for specific hardware requirements
- Implement pod anti-affinity for high availability
- Use taints and tolerations for dedicated nodes
- Consider topology spread constraints for distribution

### 3. Priority and Preemption
- Define clear priority classes
- Use PodDisruptionBudgets for critical applications
- Monitor preemption events
- Plan for capacity management

### 4. Advanced Configuration Examples

#### High-Availability Pod Deployment
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: ha-web
spec:
  replicas: 3
  template:
    spec:
      affinity:
        podAntiAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
          - labelSelector:
              matchExpressions:
              - key: app
                operator: In
                values:
                - web
            topologyKey: "kubernetes.io/hostname"
      topologySpreadConstraints:
      - maxSkew: 1
        topologyKey: topology.kubernetes.io/zone
        whenUnsatisfiable: DoNotSchedule
        labelSelector:
          matchLabels:
            app: web
      priorityClassName: high-priority
      containers:
      - name: nginx
        image: nginx
        resources:
          requests:
            memory: "64Mi"
            cpu: "250m"
          limits:
            memory: "128Mi"
            cpu: "500m"
```

#### Resource-Optimized Namespace
```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: optimized
---
apiVersion: v1
kind: ResourceQuota
metadata:
  name: compute-resources
  namespace: optimized
spec:
  hard:
    requests.cpu: "4"
    requests.memory: 4Gi
    limits.cpu: "8"
    limits.memory: 8Gi
---
apiVersion: v1
kind: LimitRange
metadata:
  name: default-limits
  namespace: optimized
spec:
  limits:
  - default:
      memory: "256Mi"
      cpu: "200m"
    defaultRequest:
      memory: "128Mi"
      cpu: "100m"
    type: Container
```