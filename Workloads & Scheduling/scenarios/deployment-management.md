# Deployment Management Scenarios

## 1. Basic Deployment Operations

### Create a Deployment
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-deployment
  labels:
    app: nginx
spec:
  replicas: 3
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
        ports:
        - containerPort: 80
```

### Rolling Update Strategy
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
      maxSurge: 1
      maxUnavailable: 1
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

## 2. Deployment Updates and Rollbacks

### Update Deployment
```bash
# Update image
kubectl set image deployment/nginx-deployment nginx=nginx:1.16.1

# Check rollout status
kubectl rollout status deployment/nginx-deployment

# View rollout history
kubectl rollout history deployment/nginx-deployment
```

### Rollback Deployment
```bash
# Rollback to previous version
kubectl rollout undo deployment/nginx-deployment

# Rollback to specific revision
kubectl rollout undo deployment/nginx-deployment --to-revision=2
```

## 3. Scaling Operations

### Manual Scaling
```bash
# Scale using command
kubectl scale deployment nginx-deployment --replicas=5

# Scale using YAML
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-deployment
spec:
  replicas: 5
```

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
  minReplicas: 1
  maxReplicas: 10
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 50
```

## 4. Advanced Deployment Configurations

### Deployment with ConfigMap
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-config-deployment
spec:
  replicas: 3
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
        image: nginx
        volumeMounts:
        - name: config-volume
          mountPath: /etc/nginx/conf.d
      volumes:
      - name: config-volume
        configMap:
          name: nginx-config
```

### Deployment with Secrets
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-secret-deployment
spec:
  replicas: 3
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
        image: nginx
        env:
        - name: SECRET_USERNAME
          valueFrom:
            secretKeyRef:
              name: mysecret
              key: username
```

## Commands Reference

### Deployment Management
```bash
# Create and update
kubectl create deployment nginx --image=nginx
kubectl apply -f deployment.yaml

# Get deployment info
kubectl get deployments
kubectl describe deployment <deployment-name>

# Update deployment
kubectl set image deployment/<deployment-name> <container>=<image>
kubectl edit deployment/<deployment-name>

# Rollout management
kubectl rollout status deployment/<deployment-name>
kubectl rollout history deployment/<deployment-name>
kubectl rollout undo deployment/<deployment-name>

# Scaling
kubectl scale deployment/<deployment-name> --replicas=<number>
```

## Troubleshooting Guide

### Common Issues

1. **Deployment Not Progressing**
```bash
# Check deployment status
kubectl describe deployment <deployment-name>

# Check pod events
kubectl get events --field-selector involvedObject.kind=Pod

# Check replica sets
kubectl get rs -l app=<app-label>
```

2. **Rolling Update Issues**
- Verify resource availability
- Check image pull status
- Validate pod readiness probes

3. **Scaling Problems**
```bash
# Check HPA status
kubectl get hpa
kubectl describe hpa <hpa-name>

# Verify metrics server
kubectl get apiservice v1beta1.metrics.k8s.io
```

### Best Practices

1. **Update Strategy**
- Use appropriate maxSurge and maxUnavailable
- Implement proper readiness probes
- Consider using pod disruption budgets

2. **Resource Management**
- Set appropriate resource requests and limits
- Use HPA for automatic scaling
- Monitor resource usage

3. **Configuration Management**
- Use ConfigMaps for configuration
- Handle secrets properly
- Implement proper environment variables

4. **Rollout Management**
- Keep deployment history for rollbacks
- Test updates in staging environment
- Monitor rollout progress

### Deployment Patterns

1. **Blue-Green Deployment**
```yaml
# Service pointing to blue deployment
apiVersion: v1
kind: Service
metadata:
  name: my-app
spec:
  selector:
    app: my-app
    version: blue
```

2. **Canary Deployment**
```yaml
# Canary deployment with traffic split
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-app-canary
spec:
  replicas: 1
  template:
    metadata:
      labels:
        app: my-app
        version: v2
```