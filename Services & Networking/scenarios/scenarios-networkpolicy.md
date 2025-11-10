# Network Policy Scenarios

## Scenario 1: Default Deny All Traffic
Task: Create a policy to deny all ingress traffic

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

```bash
# Apply policy
kubectl apply -f default-deny-ingress.yaml

# Verify
kubectl get networkpolicies
kubectl describe networkpolicy default-deny-ingress
```

## Scenario 2: Allow Traffic Between Specific Pods
Task: Allow traffic from frontend to backend pods

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-frontend-to-backend
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

## Scenario 3: Namespace Network Policy
Task: Allow traffic from specific namespace

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-from-namespace
spec:
  podSelector:
    matchLabels:
      app: web
  policyTypes:
  - Ingress
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          purpose: monitoring
```

## Scenario 4: Egress Network Policy
Task: Control outbound traffic

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: limit-egress
spec:
  podSelector:
    matchLabels:
      app: web
  policyTypes:
  - Egress
  egress:
  - to:
    - ipBlock:
        cidr: 10.0.0.0/24
    ports:
    - protocol: TCP
      port: 5978
```

## Network Policy Troubleshooting

```bash
# 1. Check Network Policy Status
kubectl get networkpolicies
kubectl describe networkpolicy <policy-name>

# 2. Verify Pod Labels
kubectl get pods --show-labels

# 3. Test Connectivity
kubectl run test-pod --image=busybox -it --rm -- wget -qO- http://service-name

# 4. Check Pod Network Status
kubectl get pods -o wide

# 5. Validate Network Policy Configuration
kubectl get networkpolicy <policy-name> -o yaml
```

## Common Network Policy Commands

```bash
# Create network policy
kubectl create networkpolicy my-policy --pod-selector=app=db

# Get network policies
kubectl get networkpolicy
kubectl get netpol

# Delete network policy
kubectl delete networkpolicy my-policy

# Edit network policy
kubectl edit networkpolicy my-policy
```