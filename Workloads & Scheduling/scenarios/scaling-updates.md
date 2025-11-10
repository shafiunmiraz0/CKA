# Scaling and Updates Management

## 1. Manual Scaling

### Scale Deployment
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-deployment
spec:
  replicas: 5  # Change this number to scale
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: nginx:1.14.2
```

```bash
# Scale using command
kubectl scale deployment nginx-deployment --replicas=3

# Scale using patch
kubectl patch deployment nginx-deployment -p '{"spec":{"replicas":4}}'
```

## 2. Automatic Scaling

### Horizontal Pod Autoscaling
```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: nginx-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: nginx-deployment
  minReplicas: 2
  maxReplicas: 10
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 80
```

### Multiple Metrics HPA
```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: multi-metric-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: app-deployment
  minReplicas: 2
  maxReplicas: 10
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 80
  - type: Resource
    resource:
      name: memory
      target:
        type: Utilization
        averageUtilization: 80
```

## 3. Rolling Updates

### Update Strategy Configuration
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-deployment
spec:
  replicas: 3
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1        # Maximum number of pods above desired number
      maxUnavailable: 1  # Maximum number of pods can be unavailable
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: nginx:1.14.2
```

### Rollback Configuration
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-deployment
spec:
  revisionHistoryLimit: 10  # Number of old ReplicaSets to retain
```

## 4. Advanced Update Strategies

### Blue-Green Deployment
```yaml
# Blue deployment
apiVersion: apps/v1
kind: Deployment
metadata:
  name: app-blue
spec:
  replicas: 3
  selector:
    matchLabels:
      app: myapp
      version: blue
  template:
    metadata:
      labels:
        app: myapp
        version: blue
    spec:
      containers:
      - name: app
        image: myapp:1.0

---
# Green deployment
apiVersion: apps/v1
kind: Deployment
metadata:
  name: app-green
spec:
  replicas: 3
  selector:
    matchLabels:
      app: myapp
      version: green
  template:
    metadata:
      labels:
        app: myapp
        version: green
    spec:
      containers:
      - name: app
        image: myapp:2.0

---
# Service to switch between blue and green
apiVersion: v1
kind: Service
metadata:
  name: myapp-service
spec:
  selector:
    app: myapp
    version: blue  # Switch to green for cutover
  ports:
  - port: 80
    targetPort: 8080
```

### Canary Deployment
```yaml
# Main deployment
apiVersion: apps/v1
kind: Deployment
metadata:
  name: app-stable
spec:
  replicas: 5
  selector:
    matchLabels:
      app: myapp
      version: stable
  template:
    metadata:
      labels:
        app: myapp
        version: stable
    spec:
      containers:
      - name: app
        image: myapp:1.0

---
# Canary deployment
apiVersion: apps/v1
kind: Deployment
metadata:
  name: app-canary
spec:
  replicas: 1
  selector:
    matchLabels:
      app: myapp
      version: canary
  template:
    metadata:
      labels:
        app: myapp
        version: canary
    spec:
      containers:
      - name: app
        image: myapp:2.0
```

## Commands Reference

### Scaling Commands
```bash
# Manual scaling
kubectl scale deployment/<name> --replicas=<number>
kubectl scale statefulset/<name> --replicas=<number>

# Autoscaling
kubectl autoscale deployment/<name> --min=2 --max=5 --cpu-percent=80

# Get scaling information
kubectl get hpa
kubectl describe hpa <name>
```

### Update Commands
```bash
# Rolling update
kubectl set image deployment/<name> container=image:version
kubectl rollout status deployment/<name>

# Rollback
kubectl rollout history deployment/<name>
kubectl rollout undo deployment/<name>
kubectl rollout undo deployment/<name> --to-revision=2

# Pause/Resume rollout
kubectl rollout pause deployment/<name>
kubectl rollout resume deployment/<name>
```

## Troubleshooting Guide

### Common Scaling Issues

1. **HPA Not Scaling**
```bash
# Check HPA status
kubectl describe hpa <name>

# Verify metrics server
kubectl get apiservice v1beta1.metrics.k8s.io

# Check pod metrics
kubectl top pods
```

2. **Manual Scaling Issues**
```bash
# Check deployment status
kubectl describe deployment <name>

# Check pod events
kubectl get events --field-selector involvedObject.kind=Pod
```

3. **Update Problems**
```bash
# Check rollout status
kubectl rollout status deployment/<name>

# View deployment conditions
kubectl get deployment <name> -o yaml | grep -A 5 conditions
```

### Best Practices

1. **Scaling**
- Set appropriate resource requests and limits
- Configure HPA thresholds based on application behavior
- Consider using custom metrics for scaling
- Test scaling behavior under load

2. **Updates**
- Use rolling updates with appropriate surge and unavailable settings
- Implement readiness probes for smooth updates
- Keep revision history for rollbacks
- Use canary deployments for critical updates

3. **Resource Management**
- Monitor resource usage during scaling
- Set appropriate QoS classes
- Use pod disruption budgets
- Consider node resources when scaling

4. **Monitoring**
- Monitor scaling events
- Track update progress
- Set up alerts for scaling issues
- Keep track of revision history