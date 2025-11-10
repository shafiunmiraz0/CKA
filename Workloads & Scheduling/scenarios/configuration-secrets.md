# Configuration and Secrets Management

## 1. ConfigMap Usage

### Create ConfigMap

```yaml
# From literal values
apiVersion: v1
kind: ConfigMap
metadata:
  name: app-config
data:
  APP_COLOR: blue
  APP_MODE: prod

# From file
apiVersion: v1
kind: ConfigMap
metadata:
  name: nginx-config
data:
  nginx.conf: |
    server {
        listen 80;
        server_name example.com;
        location / {
            proxy_pass http://backend;
        }
    }
```

### Use ConfigMap in Pod
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: config-pod
spec:
  containers:
  - name: app
    image: nginx
    env:
    - name: APP_COLOR
      valueFrom:
        configMapKeyRef:
          name: app-config
          key: APP_COLOR
    volumeMounts:
    - name: config-volume
      mountPath: /etc/nginx
  volumes:
  - name: config-volume
    configMap:
      name: nginx-config
```

## 2. Secret Management

### Create Secrets

```yaml
# From literal values
apiVersion: v1
kind: Secret
metadata:
  name: app-secret
type: Opaque
data:
  username: YWRtaW4=  # base64 encoded
  password: MWYyZDFlMmU2N2Rm

# From files
apiVersion: v1
kind: Secret
metadata:
  name: tls-secret
type: kubernetes.io/tls
data:
  tls.crt: <base64-encoded-cert>
  tls.key: <base64-encoded-key>
```

### Use Secrets in Pod
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: secret-pod
spec:
  containers:
  - name: app
    image: nginx
    env:
    - name: DB_USERNAME
      valueFrom:
        secretKeyRef:
          name: app-secret
          key: username
    volumeMounts:
    - name: secret-volume
      mountPath: /etc/secrets
      readOnly: true
  volumes:
  - name: secret-volume
    secret:
      secretName: app-secret
```

## 3. Environment Variables and Arguments

### Pod with Environment Variables
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: env-pod
spec:
  containers:
  - name: app
    image: nginx
    env:
    - name: ENVIRONMENT
      value: "production"
    - name: API_KEY
      valueFrom:
        secretKeyRef:
          name: api-secret
          key: api-key
    envFrom:
    - configMapRef:
        name: app-config
    - secretRef:
        name: app-secrets
```

### Pod with Arguments
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: command-pod
spec:
  containers:
  - name: app
    image: ubuntu
    command: ["/bin/sh"]
    args: ["-c", "while true; do echo hello; sleep 10; done"]
```

## Commands Reference

### ConfigMap Operations
```bash
# Create ConfigMap
kubectl create configmap app-config --from-literal=APP_COLOR=blue
kubectl create configmap nginx-conf --from-file=nginx.conf

# Get ConfigMap info
kubectl get configmaps
kubectl describe configmap <configmap-name>

# Edit ConfigMap
kubectl edit configmap <configmap-name>
```

### Secret Operations
```bash
# Create Secret
kubectl create secret generic app-secret \
    --from-literal=username=admin \
    --from-literal=password=t0p-Secret

# Create TLS Secret
kubectl create secret tls tls-secret \
    --cert=path/to/cert.crt \
    --key=path/to/key.key

# Get Secret info
kubectl get secrets
kubectl describe secret <secret-name>
```

## Best Practices

### 1. ConfigMap Best Practices
- Keep configurations environment-specific
- Use meaningful names for keys
- Consider using config files for complex configurations
- Update configurations without pod restarts when possible

### 2. Secret Best Practices
- Never commit secrets to version control
- Use appropriate secret types
- Rotate secrets regularly
- Limit secret access with RBAC
- Enable encryption at rest

### 3. Environment Variables
- Use meaningful variable names
- Group related variables
- Consider using environment files
- Don't leak sensitive information

## Troubleshooting Guide

### Common Issues

1. **ConfigMap Updates**
```bash
# Check if ConfigMap is updated
kubectl get configmap <name> -o yaml

# Check pod mounts
kubectl describe pod <pod-name> | grep -A 5 Mounts
```

2. **Secret Mounting Issues**
```bash
# Verify secret exists
kubectl get secret <name>

# Check pod events
kubectl describe pod <pod-name>
```

3. **Environment Variable Problems**
```bash
# Check environment variables in container
kubectl exec <pod-name> -- env

# Verify ConfigMap/Secret references
kubectl describe pod <pod-name> | grep -A 5 Environment
```

### Configuration Patterns

1. **Multiple Environment Support**
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: app-config-prod
data:
  APP_ENV: production
  API_URL: https://api.prod.example.com
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: app-config-dev
data:
  APP_ENV: development
  API_URL: https://api.dev.example.com
```

2. **Sensitive Configuration**
```yaml
apiVersion: v1
kind: Secret
metadata:
  name: app-credentials
type: Opaque
stringData:  # Automatically encoded to base64
  credentials.json: |
    {
      "apiKey": "your-api-key",
      "secret": "your-secret"
    }
```

3. **Update Strategy**
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: app
spec:
  template:
    metadata:
      annotations:
        checksum/config: ${CONFIG_CHECKSUM}  # Update to force pod restart
    spec:
      containers:
      - name: app
        image: nginx
```