# Network Policy Configuration

## Scenario Description
Implement and manage Network Policies to control pod-to-pod communication.

## Requirements
1. Create default deny policy
2. Allow specific ingress traffic
3. Allow specific egress traffic
4. Test network policies

## Solution

### 1. Default Deny Policy
```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny-ingress
spec:
  podSelector: {}
  policyTypes:
  - Ingress
```

### 2. Allow Specific Traffic
```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-frontend-backend
spec:
  podSelector:
    matchLabels:
      app: backend
  policyTypes:
  - Ingress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          app: frontend
    ports:
    - protocol: TCP
      port: 8080
```

### 3. Test Environment Setup
```yaml
# Frontend Deployment
apiVersion: apps/v1
kind: Deployment
metadata:
  name: frontend
spec:
  replicas: 2
  selector:
    matchLabels:
      app: frontend
  template:
    metadata:
      labels:
        app: frontend
    spec:
      containers:
      - name: nginx
        image: nginx:1.14.2
---
# Backend Deployment
apiVersion: apps/v1
kind: Deployment
metadata:
  name: backend
spec:
  replicas: 2
  selector:
    matchLabels:
      app: backend
  template:
    metadata:
      labels:
        app: backend
    spec:
      containers:
      - name: nginx
        image: nginx:1.14.2
```

## Common Network Policy Commands
```bash
# List network policies
kubectl get networkpolicy
kubectl get netpol

# Describe network policy
kubectl describe networkpolicy allow-frontend-backend

# Delete network policy
kubectl delete networkpolicy default-deny-ingress
```

## Troubleshooting Steps

### 1. Verify Policy Configuration
```bash
# Check policy details
kubectl get networkpolicy -o yaml

# Verify pod labels
kubectl get pods --show-labels
```

### 2. Test Connectivity
```bash
# Test from frontend to backend
kubectl exec -it frontend-pod -- wget -qO- http://backend-service

# Test from unauthorized pod
kubectl exec -it other-pod -- wget -qO- http://backend-service
```

### 3. Debug Network Issues
```bash
# Run network debug pod
kubectl run tmp-shell --rm -i --tty --image nicolaka/netshoot -- /bin/bash
```

## Advanced Policy Examples

### 1. Allow DNS Access
```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-dns
spec:
  podSelector: {}
  policyTypes:
  - Egress
  egress:
  - to:
    - namespaceSelector:
        matchLabels:
          kubernetes.io/metadata.name: kube-system
    ports:
    - protocol: UDP
      port: 53
```

### 2. Multi-Port Policy
```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: multi-port-egress
spec:
  podSelector:
    matchLabels:
      app: web
  policyTypes:
  - Egress
  egress:
  - to:
    - podSelector:
        matchLabels:
          app: db
    ports:
    - protocol: TCP
      port: 3306
    - protocol: TCP
      port: 5432
```

### 3. Namespace Policy
```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-from-dev
spec:
  podSelector:
    matchLabels:
      app: api
  policyTypes:
  - Ingress
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          environment: dev
```

## Best Practices

1. Policy Design:
   - Start with deny-all
   - Use specific selectors
   - Document policies
   - Test thoroughly

2. Security:
   - Implement least privilege
   - Control both ingress and egress
   - Regularly audit policies

3. Maintenance:
   - Label pods consistently
   - Monitor policy effects
   - Keep policies updated

## Testing Scenarios
```bash
# 1. Test default deny
kubectl run test-pod --image=busybox --rm -it -- wget -qO- http://backend-service

# 2. Test allowed communication
kubectl exec -it frontend-pod -- wget -qO- http://backend-service

# 3. Test namespace isolation
kubectl exec -it -n dev test-pod -- wget -qO- http://backend-service.prod

# 4. Test egress policy
kubectl exec -it frontend-pod -- ping 8.8.8.8
```