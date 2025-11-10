# Deployment Troubleshooting Scenarios

## Common Deployment Issues

### 1. Deployment Not Progressing
**Symptoms:**
- New pods not being created
- Old pods not being terminated
- Deployment shows "Progressing" but no progress

**Debugging Steps:**
```bash
# Check deployment status
kubectl describe deployment <deployment-name>

# Check replica set status
kubectl get rs -l app=<app-label>

# Check pod events
kubectl get events --field-selector involvedObject.kind=Pod
```

**Common Causes:**
- Insufficient resources
- Image pull errors
- Readiness probe failures
- Pod disruption budget preventing updates

### 2. Deployment Rollout Issues
**Symptoms:**
- Failed rollout
- Stuck in rolling update

**Debugging Steps:**
```bash
# Check rollout status
kubectl rollout status deployment/<deployment-name>

# Check rollout history
kubectl rollout history deployment/<deployment-name>

# View revision details
kubectl rollout history deployment/<deployment-name> --revision=2
```

**Example Deployment YAML:**
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: example-deployment
spec:
  replicas: 3
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1
      maxUnavailable: 1
  selector:
    matchLabels:
      app: example
  template:
    metadata:
      labels:
        app: example
    spec:
      containers:
      - name: app
        image: nginx:1.19
        readinessProbe:
          httpGet:
            path: /
            port: 80
          initialDelaySeconds: 5
          periodSeconds: 5
```

### 3. Scaling Issues
**Symptoms:**
- Deployment not scaling up/down
- Incorrect number of replicas

**Debugging Steps:**
```bash
# Check HPA if configured
kubectl get hpa
kubectl describe hpa <hpa-name>

# Check deployment scaling
kubectl scale deployment/<deployment-name> --replicas=3

# Check pod distribution
kubectl get pods -o wide
```

### 4. Update Strategy Issues
**Symptoms:**
- Slow rollouts
- Failed updates
- Rollback failures

**Debugging Steps:**
```bash
# Check current strategy
kubectl get deployment <deployment-name> -o jsonpath='{.spec.strategy.type}'

# Rollback to previous version
kubectl rollout undo deployment/<deployment-name>

# Pause/Resume rollout
kubectl rollout pause deployment/<deployment-name>
kubectl rollout resume deployment/<deployment-name>
```

## Quick Reference Commands

```bash
# Get deployment status
kubectl get deployment <deployment-name> -o wide

# Check replica sets
kubectl get rs -l app=<app-label>

# View deployment details
kubectl describe deployment <deployment-name>

# Check deployment history
kubectl rollout history deployment/<deployment-name>

# Force rollback
kubectl rollout undo deployment/<deployment-name> --to-revision=<revision>

# Delete deployment
kubectl delete deployment <deployment-name>
```

## Common Deployment Configurations

### Blue-Green Deployment
```yaml
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
```

### Canary Deployment
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: app-canary
spec:
  replicas: 1
  selector:
    matchLabels:
      app: myapp
      track: canary
  template:
    metadata:
      labels:
        app: myapp
        track: canary
    spec:
      containers:
      - name: app
        image: myapp:2.0
```