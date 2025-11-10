# Network Troubleshooting Scenarios

## Common Network Issues

### 1. Service Connectivity Issues
**Symptoms:**
- Services not accessible
- Connection timeouts
- DNS resolution failures

**Debugging Steps:**
```bash
# Check service details
kubectl get svc <service-name> -o wide
kubectl describe svc <service-name>

# Verify endpoint creation
kubectl get endpoints <service-name>

# Test DNS resolution
kubectl run -it --rm debug --image=busybox -- nslookup <service-name>.<namespace>.svc.cluster.local
```

**Example Debug Pod:**
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: network-debug
spec:
  containers:
  - name: network-debug
    image: nicolaka/netshoot
    command:
      - sleep
      - "3600"
```

### 2. Network Policy Issues
**Symptoms:**
- Blocked connections between pods
- Unexpected connection failures
- Ingress/Egress traffic issues

**Debugging Steps:**
```bash
# List network policies
kubectl get networkpolicy

# Describe specific policy
kubectl describe networkpolicy <policy-name>

# Test connectivity
kubectl exec -it <pod-name> -- nc -zv <target-service> <port>
```

**Example NetworkPolicy:**
```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: test-network-policy
spec:
  podSelector:
    matchLabels:
      role: db
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          role: frontend
    ports:
    - protocol: TCP
      port: 3306
```

### 3. DNS Resolution Problems
**Symptoms:**
- DNS queries failing
- Service discovery issues
- CoreDNS pods not running

**Debugging Steps:**
```bash
# Check CoreDNS pods
kubectl get pods -n kube-system -l k8s-app=kube-dns

# Check CoreDNS logs
kubectl logs -n kube-system -l k8s-app=kube-dns

# Test DNS resolution
kubectl run -it --rm debug --image=busybox -- nslookup kubernetes.default
```

### 4. Ingress Controller Issues
**Symptoms:**
- External access not working
- SSL/TLS errors
- Path routing issues

**Debugging Steps:**
```bash
# Check ingress status
kubectl get ingress
kubectl describe ingress <ingress-name>

# Verify ingress controller pods
kubectl get pods -n ingress-nginx

# Check ingress controller logs
kubectl logs -n ingress-nginx -l app.kubernetes.io/component=controller
```

**Example Ingress:**
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: example-ingress
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
spec:
  rules:
  - host: example.com
    http:
      paths:
      - path: /app
        pathType: Prefix
        backend:
          service:
            name: example-service
            port:
              number: 80
```

## Quick Reference Commands

```bash
# Check cluster networking
kubectl get nodes -o wide
kubectl get pods -o wide
kubectl get services

# Test network connectivity
kubectl exec -it <pod-name> -- wget -O- <service-name>
kubectl exec -it <pod-name> -- curl <service-name>

# Check DNS resolution
kubectl exec -it <pod-name> -- nslookup <service-name>
kubectl exec -it <pod-name> -- cat /etc/resolv.conf

# Port forwarding for testing
kubectl port-forward svc/<service-name> <local-port>:<service-port>

# Check network policies
kubectl get networkpolicies --all-namespaces
```

## Network Debugging Tools

### 1. DNS Utils Pod
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: dnsutils
spec:
  containers:
  - name: dnsutils
    image: gcr.io/kubernetes-e2e-test-images/dnsutils:1.3
    command:
      - sleep
      - "3600"
```

### 2. Network Debugging Pod
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: netshoot
spec:
  containers:
  - name: netshoot
    image: nicolaka/netshoot
    command:
      - sleep
      - "3600"
```