# CoreDNS Scenarios

## Scenario 1: Verify CoreDNS Setup
Task: Check CoreDNS configuration and status

```bash
# Check CoreDNS pods
kubectl get pods -n kube-system -l k8s-app=kube-dns

# View CoreDNS configmap
kubectl get configmap coredns -n kube-system -o yaml

# Check CoreDNS service
kubectl get svc -n kube-system kube-dns
```

## Scenario 2: DNS Resolution Testing
Task: Test DNS resolution for services and pods

```bash
# Test service DNS resolution
kubectl run test-dns --image=busybox -it --rm -- nslookup kubernetes.default

# Test pod DNS resolution
kubectl run test-dns --image=busybox -it --rm -- nslookup <pod-ip>.default.pod.cluster.local

# Check DNS configuration in pod
kubectl run test-dns --image=busybox -it --rm -- cat /etc/resolv.conf
```

## Scenario 3: Custom DNS Configuration
Task: Modify CoreDNS configuration

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

## Scenario 4: Troubleshooting DNS Issues
Task: Debug common DNS problems

```bash
# 1. Check CoreDNS pods status
kubectl get pods -n kube-system -l k8s-app=kube-dns
kubectl logs -n kube-system -l k8s-app=kube-dns

# 2. Verify CoreDNS service
kubectl get svc -n kube-system kube-dns

# 3. Test DNS resolution from pod
kubectl run test-dns --image=busybox -it --rm -- nslookup kubernetes.default

# 4. Check pod DNS config
kubectl run test-dns --image=busybox -it --rm -- cat /etc/resolv.conf

# 5. Verify cluster DNS settings
kubectl describe pods -n kube-system -l k8s-app=kube-dns | grep ClusterIP
```