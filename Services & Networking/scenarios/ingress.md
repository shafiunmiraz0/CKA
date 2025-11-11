# Ingress Configuration and Management

## Scenario Description
Set up and configure Ingress resources for external access to services.

## Requirements
1. Install Ingress Controller
2. Configure basic Ingress rules
3. Set up TLS termination
4. Implement path-based routing

## Solution

### 1. Install NGINX Ingress Controller
```bash
# Using Helm
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm install nginx-ingress ingress-nginx/ingress-nginx

# Or using manifest
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.8.1/deploy/static/provider/cloud/deploy.yaml
```

### 2. Basic Ingress Configuration
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: basic-ingress
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
spec:
  ingressClassName: nginx
  rules:
  - host: myapp.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: myapp-service
            port:
              number: 80
```

### 3. TLS Configuration
```yaml
apiVersion: v1
kind: Secret
metadata:
  name: tls-secret
type: kubernetes.io/tls
data:
  tls.crt: base64_encoded_cert
  tls.key: base64_encoded_key
---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: tls-ingress
spec:
  ingressClassName: nginx
  tls:
  - hosts:
    - myapp.example.com
    secretName: tls-secret
  rules:
  - host: myapp.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: myapp-service
            port:
              number: 80
```

## Common Commands

### Ingress Management
```bash
# List ingress resources
kubectl get ingress
kubectl get ing

# Describe ingress
kubectl describe ingress basic-ingress

# Get ingress controller pods
kubectl get pods -n ingress-nginx

# Check ingress controller logs
kubectl logs -n ingress-nginx -l app.kubernetes.io/name=ingress-nginx
```

### Certificate Management
```bash
# Create TLS secret
kubectl create secret tls tls-secret --cert=path/to/cert --key=path/to/key

# Check secrets
kubectl get secrets
```

## Troubleshooting Steps

### 1. Ingress Controller Issues
```bash
# Check controller status
kubectl get pods -n ingress-nginx
kubectl describe pod -n ingress-nginx <ingress-controller-pod>

# View controller logs
kubectl logs -n ingress-nginx <ingress-controller-pod>
```

### 2. Ingress Rule Problems
```bash
# Verify ingress configuration
kubectl describe ingress <ingress-name>

# Check backend services
kubectl get svc
kubectl describe svc <service-name>
```

### 3. TLS Issues
```bash
# Verify TLS secret
kubectl describe secret tls-secret

# Test TLS connection
curl -v -k https://myapp.example.com
```

## Advanced Configurations

### 1. Path-Based Routing
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: path-based-ingress
spec:
  ingressClassName: nginx
  rules:
  - host: myapp.example.com
    http:
      paths:
      - path: /api
        pathType: Prefix
        backend:
          service:
            name: api-service
            port:
              number: 80
      - path: /web
        pathType: Prefix
        backend:
          service:
            name: web-service
            port:
              number: 80
```

### 2. Rate Limiting
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: rate-limit-ingress
  annotations:
    nginx.ingress.kubernetes.io/limit-rps: "10"
spec:
  ingressClassName: nginx
  rules:
  - host: myapp.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: myapp-service
            port:
              number: 80
```

## Best Practices

1. Security:
   - Always use TLS
   - Implement rate limiting
   - Use authentication when needed
   - Regular certificate rotation

2. Performance:
   - Configure proper buffer sizes
   - Set appropriate timeouts
   - Monitor resource usage
   - Use caching when possible

3. Maintenance:
   - Regular controller updates
   - Backup TLS certificates
   - Monitor logs
   - Document configurations

## Testing and Validation

1. Basic Connectivity
```bash
# Test HTTP
curl -H "Host: myapp.example.com" http://<ingress-ip>

# Test HTTPS
curl -k -H "Host: myapp.example.com" https://<ingress-ip>
```

2. Path Routing
```bash
# Test different paths
curl -H "Host: myapp.example.com" http://<ingress-ip>/api
curl -H "Host: myapp.example.com" http://<ingress-ip>/web
```

3. TLS Verification
```bash
# Check certificate
openssl s_client -connect <ingress-ip>:443 -servername myapp.example.com
```