# Kubernetes Services & Networking Guide

A comprehensive guide to Kubernetes networking concepts, commands, and configurations.

## Table of Contents
- [Service Types](#service-types)
- [Quick Commands](#quick-commands)
- [DNS & Connectivity](#dns--connectivity)
- [Ingress Configuration](#ingress-configuration)
- [Network Policies](#network-policies)
- [Troubleshooting](#troubleshooting)
- [YAML Examples](#yaml-examples)

## Service Types

| Type | Description | Use Case |
|------|-------------|----------|
| **ClusterIP** | Internal service, accessible within cluster | Inter-service communication |
| **NodePort** | Exposes service on each node's IP | Development, quick external access |
| **LoadBalancer** | Cloud provider load balancer | Production external access |
| **ExternalName** | DNS CNAME record | External service mapping |

## Quick Commands

### Service Management
```bash
# Expose deployments
kubectl expose deployment/nginx --port=80 --target-port=80 --name=nginx-svc
kubectl expose deployment/nginx --type=NodePort --port=80
kubectl expose deployment/nginx --type=LoadBalancer --port=80

# Service operations
kubectl get services
kubectl describe service nginx
kubectl delete service nginx
```

### Endpoints & Discovery
```bash
# Check service endpoints
kubectl get endpoints nginx-svc
kubectl get endpointslices -n <namespace>

# Inspect service details
kubectl describe svc <service-name> -n <namespace>
```

### Port Forwarding
```bash
# Forward to service
kubectl port-forward svc/my-svc 8080:80

# Forward to pod
kubectl port-forward <pod-name> 8080:80 -n <namespace>

# API proxy
kubectl proxy --port=8001
```

## DNS & Connectivity

### DNS Testing
```bash
# Start debug pod
kubectl run -i --tty dnsutils --image=tianon/dnsutils --restart=Never --rm -- bash -il

# Inside container tests
nslookup kubernetes.default
nslookup <service-name>.<namespace>.svc.cluster.local
ping <service-name>
```

### CoreDNS Checks
```bash
# Check CoreDNS pods
kubectl get pods -n kube-system -l k8s-app=kube-dns

# Check CoreDNS logs
kubectl logs -n kube-system -l k8s-app=kube-dns
```

## Ingress Configuration

### Basic Ingress
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: example-ingress
spec:
  rules:
  - host: example.local
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: nginx-svc
            port:
              number: 80
```

### Ingress Commands
```bash
# List ingress resources
kubectl get ingress
kubectl describe ingress my-ingress

# Check ingress controller
kubectl get pods -n ingress-nginx
```

## Network Policies

### Deny All Policy
```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: deny-all
  namespace: default
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  - Egress
```

### Network Policy Commands
```bash
# List policies
kubectl get networkpolicies
kubectl get netpol -n <namespace>

# Inspect policy
kubectl describe networkpolicy my-policy -n <namespace>
```

## Troubleshooting

### Cluster Networking
```bash
# Check CNI plugins
kubectl -n kube-system get pods

# Check kube-proxy
kubectl -n kube-system get pods -l k8s-app=kube-proxy
kubectl -n kube-system describe daemonset kube-proxy
```

### Service Discovery
```bash
# Check all services and endpoints
kubectl get svc -A
kubectl get ep -A

# Cluster diagnostics
kubectl cluster-info dump --namespaces=kube-system
```

### API Resources
```bash
# Inspect available resources
kubectl api-resources
kubectl get endpointslice -A
```

## YAML Examples

### Basic Service
```yaml
apiVersion: v1
kind: Service
metadata:
  name: my-service
spec:
  selector:
    app: my-app
  ports:
    - protocol: TCP
      port: 80
      targetPort: 8080
  type: ClusterIP
```

### Network Policy (Allow DNS)
```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-dns
  namespace: default
spec:
  podSelector: {}
  policyTypes:
  - Egress
  egress:
  - to:
    - namespaceSelector: {}
      podSelector:
        matchLabels:
          k8s-app: kube-dns
    ports:
    - protocol: UDP
      port: 53
```

## Security & Observability

### Security Checks
```bash
# Network policy inspection
kubectl get networkpolicy -n <namespace>
kubectl describe networkpolicy <name> -n <namespace>

# Connectivity testing
kubectl run -i --tty dnsutils --image=tianon/dnsutils --restart=Never --rm -- bash -il
```

### Monitoring
```bash
# Metrics server (install from snippets)
# kubectl apply -f ../snippets/metrics-server.yaml

# Resource usage
kubectl top nodes
kubectl top pods
```

## Snippets Reference

Available YAML snippets in `../snippets/` directory:

- `ingress-tls.yaml` - Ingress with TLS termination
- `networkpolicy-deny-allow.yaml` - Network policy examples
- `networkpolicy-allow-dns.yaml` - DNS egress policies
- `ingress-basic.yaml` - Simple ingress configuration
- `configmap-secret.yaml` - ConfigMap and Secret examples
- `metrics-server.yaml` - Metrics server installation
- `podsecurity-namespace-labels.yaml` - Security context labels

## Best Practices

### Service Configuration
- Use meaningful service names
- Match service ports to container ports
- Use appropriate service types for your environment

### Network Policies
- Start with deny-all policies
- Gradually add allow rules
- Test policies thoroughly
- Document all network rules

### Ingress
- Install ingress controller first
- Configure TLS properly
- Set up default backends
- Monitor ingress controller logs

### Troubleshooting
1. Check service endpoints
2. Verify pod selectors match
3. Test DNS resolution
4. Check network policies
5. Inspect ingress controller

## Quick Reference

```bash
# Apply common configurations
kubectl apply -f ../snippets/networkpolicy-allow-dns.yaml
kubectl apply -f ../snippets/ingress-basic.yaml

# Quick diagnostics
kubectl get svc,ep,ingress,networkpolicies -A
kubectl describe svc <service-name>
```

---

*For more detailed examples and advanced configurations, refer to the snippets directory.*