# Deployment Scaling (Manual & Autoscaling)

## Manual Scaling

### Commands
```bash
# Scale a deployment manually
kubectl scale deployment/<name> --replicas=<n>

# Patch replicas
kubectl patch deployment <name> -p '{"spec":{"replicas":3}}'

# Force a rolling restart
kubectl rollout restart deployment/<name>
```

### YAML snippet (scale change)
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-deploy
spec:
  replicas: 5
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
        image: nginx:1.14
```

## Horizontal Pod Autoscaler (HPA)

### HPA YAML (CPU-based)
```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: nginx-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: nginx-deploy
  minReplicas: 2
  maxReplicas: 10
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 50
```

### Commands for HPA
```bash
# Create HPA
kubectl apply -f hpa.yaml

# Get HPA status
kubectl get hpa
kubectl describe hpa nginx-hpa

# Check pod metrics (metrics-server required)
kubectl top pods
```

## Troubleshooting
- HPA not scaling: verify metrics-server is running and `kubectl get apiservice` for metrics API.
- Scaling too slow: check `minReplicas` and metric thresholds.
- Pod scheduling failures after scaling: ensure node capacity and quotas.

## Exam tips
- Use `kubectl scale` for quick manual scaling during tasks.
- Validate HPA with `kubectl top pods` and `kubectl describe hpa`.
