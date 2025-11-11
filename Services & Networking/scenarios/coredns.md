# CoreDNS Configuration and Troubleshooting

## Scenario Description
Configure and troubleshoot CoreDNS in a Kubernetes cluster for service discovery.

## Requirements
1. Verify CoreDNS deployment
2. Configure custom DNS settings
3. Troubleshoot DNS resolution issues
4. Test service discovery

## Solution

### 1. CoreDNS Verification
```bash
# Check CoreDNS pods
kubectl get pods -n kube-system -l k8s-app=kube-dns

# View CoreDNS configuration
kubectl get configmap coredns -n kube-system -o yaml

# Check CoreDNS logs
kubectl logs -n kube-system -l k8s-app=kube-dns
```

### 2. CoreDNS Configuration
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: coredns
  namespace: kube-system
data:
  Corefile: |
    .:53 {
        errors
        health {
           lameduck 5s
        }
        ready
        kubernetes cluster.local in-addr.arpa ip6.arpa {
           pods insecure
           fallthrough in-addr.arpa ip6.arpa
           ttl 30
        }
        prometheus :9153
        forward . /etc/resolv.conf
        cache 30
        loop
        reload
        loadbalance
    }
```

### 3. DNS Testing Tools
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: dnsutils
spec:
  containers:
  - name: dnsutils
    image: tutum/dnsutils
    command:
    - sleep
    - "infinity"
```

## Common DNS Commands
```bash
# Test service DNS resolution
kubectl exec -it dnsutils -- nslookup kubernetes.default

# Test pod DNS resolution
kubectl exec -it dnsutils -- nslookup <pod-ip>.<namespace>.pod.cluster.local

# Test service DNS resolution
kubectl exec -it dnsutils -- nslookup <service-name>.<namespace>.svc.cluster.local

# Check DNS configuration in pod
kubectl exec -it dnsutils -- cat /etc/resolv.conf
```

## Troubleshooting Steps

### 1. DNS Resolution Issues
```bash
# Check CoreDNS pods status
kubectl get pods -n kube-system -l k8s-app=kube-dns -o wide

# Check CoreDNS service
kubectl get svc -n kube-system kube-dns

# Verify kube-proxy is running
kubectl get pods -n kube-system -l k8s-app=kube-proxy
```

### 2. Pod DNS Configuration
```bash
# Check pod DNS config
kubectl exec -it <pod-name> -- cat /etc/resolv.conf

# Verify DNS policy
kubectl get pod <pod-name> -o yaml | grep dnsPolicy
```

### 3. CoreDNS Performance
```bash
# Check CoreDNS metrics
kubectl port-forward -n kube-system deployment/coredns 9153:9153
# Then access http://localhost:9153/metrics

# Monitor DNS queries
kubectl logs -n kube-system -l k8s-app=kube-dns
```

## Best Practices

1. DNS Configuration:
   - Use appropriate DNS policy for pods
   - Configure proper TTL values
   - Enable DNS autoscaling

2. Monitoring:
   - Monitor CoreDNS metrics
   - Set up alerts for DNS failures
   - Keep logs for troubleshooting

3. Performance:
   - Configure proper cache settings
   - Use DNS horizontal pod autoscaling
   - Monitor resource usage

## Additional YAML Templates

### Custom DNS Config Pod
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: custom-dns-pod
spec:
  containers:
  - name: nginx
    image: nginx
  dnsPolicy: "None"
  dnsConfig:
    nameservers:
      - 10.96.0.10
    searches:
      - default.svc.cluster.local
      - svc.cluster.local
      - cluster.local
    options:
      - name: ndots
        value: "5"
```

### CoreDNS HPA
```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: coredns-hpa
  namespace: kube-system
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: coredns
  minReplicas: 2
  maxReplicas: 5
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 60
```