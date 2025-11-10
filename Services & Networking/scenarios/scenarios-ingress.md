# Ingress Scenarios

## Scenario 1: Basic Ingress Setup
Task: Create a simple Ingress resource

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: basic-ingress
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

```bash
# Create ingress
kubectl apply -f basic-ingress.yaml

# Verify ingress
kubectl get ingress
kubectl describe ingress basic-ingress
```

## Scenario 2: Ingress with Multiple Paths
Task: Configure ingress with different paths

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: multi-path-ingress
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

## Scenario 3: TLS Configuration
Task: Add TLS to Ingress

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: tls-secret
type: kubernetes.io/tls
data:
  tls.crt: <base64-encoded-cert>
  tls.key: <base64-encoded-key>
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

## Scenario 4: Troubleshooting Ingress
Task: Debug common ingress issues

```bash
# 1. Check Ingress Controller
kubectl get pods -n ingress-nginx
kubectl logs -n ingress-nginx -l app.kubernetes.io/name=ingress-nginx

# 2. Verify Ingress Resource
kubectl get ingress
kubectl describe ingress my-ingress

# 3. Check Backend Services
kubectl get svc -o wide
kubectl describe svc my-service

# 4. Test Connectivity
kubectl run test-curl --image=curlimages/curl -it --rm -- curl -v http://myapp.example.com

# 5. Check Ingress Controller Service
kubectl get svc -n ingress-nginx
```

## Quick Commands for Ingress Management

```bash
# Create ingress
kubectl create ingress my-ingress --rule="foo.com/path*=service:8080"

# Get ingress status
kubectl get ingress --all-namespaces

# Edit ingress
kubectl edit ingress my-ingress

# Delete ingress
kubectl delete ingress my-ingress

# Get ingress controller details
kubectl get pods,svc -n ingress-nginx
```