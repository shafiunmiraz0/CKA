# Pod Management Scenarios

## 1. Basic Pod Creation and Management

### Single Container Pod
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: nginx-pod
  labels:
    app: nginx
spec:
  containers:
  - name: nginx
    image: nginx:1.14.2
    ports:
    - containerPort: 80
    resources:
      requests:
        memory: "64Mi"
        cpu: "250m"
      limits:
        memory: "128Mi"
        cpu: "500m"
```

### Multi-Container Pod
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: multi-container-pod
spec:
  containers:
  - name: nginx
    image: nginx
    ports:
    - containerPort: 80
  - name: redis
    image: redis
    ports:
    - containerPort: 6379
```

## 2. Pod Scheduling

### Pod with Node Selector
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: nginx-pod
spec:
  containers:
  - name: nginx
    image: nginx
  nodeSelector:
    disk: ssd
```

### Pod with Node Affinity
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: nginx-pod-affinity
spec:
  containers:
  - name: nginx
    image: nginx
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
```

## 3. Resource Management

### Pod with Resource Requests and Limits
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: resource-pod
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

### Pod with Quality of Service
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: qos-pod
spec:
  containers:
  - name: qos-container
    image: nginx
    resources:
      limits:
        memory: "200Mi"
        cpu: "700m"
      requests:
        memory: "200Mi"
        cpu: "700m"
```

## 4. Pod Lifecycle

### Pod with Lifecycle Hooks
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: lifecycle-pod
spec:
  containers:
  - name: lifecycle-container
    image: nginx
    lifecycle:
      postStart:
        exec:
          command: ["/bin/sh", "-c", "echo Hello from postStart handler > /usr/share/message"]
      preStop:
        exec:
          command: ["/bin/sh","-c","nginx -s quit; while killall -0 nginx; do sleep 1; done"]
```

### Pod with Init Containers
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: init-pod
spec:
  initContainers:
  - name: init-service
    image: busybox:1.28
    command: ['sh', '-c', 'until nslookup myservice; do echo waiting for myservice; sleep 2; done;']
  containers:
  - name: app
    image: nginx
```

## Commands Reference

### Pod Management
```bash
# Create pod
kubectl run nginx --image=nginx

# Get pod information
kubectl get pods -o wide
kubectl describe pod <pod-name>

# Access pod
kubectl exec -it <pod-name> -- /bin/bash
kubectl logs <pod-name>
kubectl logs <pod-name> -c <container-name>  # for multi-container pods

# Delete pod
kubectl delete pod <pod-name>
```

### Pod Scheduling
```bash
# Label nodes
kubectl label nodes <node-name> disk=ssd

# Check pod scheduling
kubectl get pods -o wide
kubectl describe pod <pod-name> | grep Node:
```

### Resource Management
```bash
# Check resource usage
kubectl top pod <pod-name>
kubectl describe pod <pod-name> | grep -A 3 Requests
```

## Troubleshooting Guide

### Common Issues

1. **Pod in Pending State**
- Check node resources
- Verify node selectors/affinity
- Check PVC binding (if using volumes)

2. **Pod in CrashLoopBackOff**
```bash
kubectl logs <pod-name> --previous
kubectl describe pod <pod-name>
```

3. **Pod in ImagePullBackOff**
- Verify image name
- Check image pull secrets
- Ensure registry access

4. **Resource Constraints**
```bash
kubectl describe node <node-name> | grep -A 5 "Allocated resources"
kubectl top nodes
```

### Best Practices

1. **Resource Management**
- Always set resource requests and limits
- Use appropriate QoS classes
- Monitor resource usage

2. **Pod Design**
- Use labels and annotations effectively
- Implement proper health checks
- Configure appropriate security contexts

3. **Scheduling**
- Use node affinity for specific requirements
- Implement pod anti-affinity for high availability
- Set appropriate node selectors

4. **Lifecycle Management**
- Implement proper lifecycle hooks
- Use init containers when needed
- Handle termination gracefully