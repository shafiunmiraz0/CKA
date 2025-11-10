# CoreDNS Advanced Scenarios

## Scenario 1: Custom DNS Records
Task: Add custom DNS entries to CoreDNS

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
        health
        hosts {
          192.168.1.10 custom.example.com
          fallthrough
        }
        kubernetes cluster.local in-addr.arpa ip6.arpa {
           pods insecure
           fallthrough in-addr.arpa ip6.arpa
        }
        prometheus :9153
        forward . /etc/resolv.conf
        cache 30
        loop
        reload
        loadbalance
    }
```

## Scenario 2: DNS Policy Configuration
Task: Configure pod DNS policy

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: custom-dns-pod
spec:
  dnsPolicy: "None"
  dnsConfig:
    nameservers:
      - 10.96.0.10
    searches:
      - ns1.svc.cluster.local
      - my.dns.search.suffix
    options:
      - name: ndots
        value: "2"
  containers:
  - name: dns-example
    image: nginx
```

## Scenario 3: CoreDNS Metrics
Task: Monitor CoreDNS performance

```bash
# View CoreDNS metrics
kubectl port-forward -n kube-system svc/kube-dns 9153:9153

# In another terminal:
curl localhost:9153/metrics

# Check specific metrics
curl localhost:9153/metrics | grep coredns_dns_requests_total
```

## Scenario 4: DNS Debugging Tools
Task: Use various tools to debug DNS issues

```bash
# 1. Create a debug pod with DNS tools
cat <<EOF | kubectl apply -f -
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
EOF

# 2. Run DNS tests
kubectl exec -it dnsutils -- dig kubernetes.default.svc.cluster.local

# 3. Check DNS resolution for different service types
kubectl exec -it dnsutils -- dig @10.96.0.10 myservice.default.svc.cluster.local

# 4. Verify reverse DNS
kubectl exec -it dnsutils -- dig -x <pod-ip>

# 5. Test external name resolution
kubectl exec -it dnsutils -- dig kubernetes.io
```

## CoreDNS Troubleshooting Guide

1. Check CoreDNS Pod Status:
```bash
kubectl get pods -n kube-system -l k8s-app=kube-dns -o wide
```

2. View CoreDNS Logs:
```bash
kubectl logs -n kube-system -l k8s-app=kube-dns
```

3. Verify CoreDNS Service:
```bash
kubectl get svc -n kube-system kube-dns
```

4. Test DNS Resolution:
```bash
# Internal service
kubectl run test --image=busybox -it --rm -- nslookup kubernetes.default

# Pod DNS
kubectl run test --image=busybox -it --rm -- nslookup <pod-ip>.default.pod.cluster.local
```

5. Check DNS Configuration:
```bash
# View pod DNS config
kubectl run test --image=busybox -it --rm -- cat /etc/resolv.conf

# Check CoreDNS configmap
kubectl get configmap coredns -n kube-system -o yaml
```