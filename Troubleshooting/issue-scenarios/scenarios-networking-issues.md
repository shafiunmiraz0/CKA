# Networking Troubleshooting Scenarios

## Network Policy Issue: Pod Cannot Reach Service

**Symptoms:**
- Pod cannot ping/curl another service
- Pods in same namespace can't communicate
- Only specific pods blocked

## Quick Diagnosis
```bash
# Test connectivity from pod
kubectl run -it debug --image=curlimages/curl --rm -- curl http://<service-ip>:80

# If timeout or refused:
# 1. Check if service exists
kubectl get svc <service-name>

# 2. Check service endpoints
kubectl get endpoints <service-name>

# 3. Check if network policies exist
kubectl get networkpolicy -A

# 4. Check if default deny policy
kubectl get networkpolicy -n <namespace> -o yaml | grep -A 5 "podSelector"

# 5. Test DNS resolution
kubectl run -it debug --image=curlimages/curl --rm -- nslookup <service-name>
```

## Common Causes & Fixes

### Cause 1: Default Deny Network Policy
```bash
# Check if default deny policy exists
kubectl get networkpolicy -n <namespace>

# Example restrictive policy:
# NAME                    POD-SELECTOR        AGE
# default-deny-ingress    <none>              1h  (← Blocks all incoming)

# View the policy
kubectl describe networkpolicy default-deny-ingress -n <namespace>

# Should show:
# Pod Selector:  <none> (all pods)
# Policy Types:  Ingress
# Ingress:       <none> (no ingress allowed)

# Fix: Create allow policy for pods that need traffic
kubectl apply -f - <<EOF
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-from-app
  namespace: <namespace>
spec:
  podSelector:
    matchLabels:
      app: web
  policyTypes:
  - Ingress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          app: client
    ports:
    - protocol: TCP
      port: 80
EOF
```

### Cause 2: Egress Denied
```bash
# Check if egress blocked
kubectl get networkpolicy -n <namespace> -o yaml | grep -i egress

# If egress policy exists but is empty/restrictive:
# podSelector: {}
# policyTypes:
# - Egress
# egress: []  # ← No egress allowed

# Fix: Add egress rule
kubectl patch networkpolicy <policy-name> -p '{
  "spec":{
    "egress":[{
      "to":[{"podSelector":{}}],
      "ports":[{"protocol":"TCP","port":80}]
    }]
  }
}' -n <namespace>
```

### Cause 3: Label Selector Mismatch
```bash
# Check network policy selector
kubectl get networkpolicy <policy-name> -o yaml | grep -A 3 "podSelector"

# Example:
# podSelector:
#   matchLabels:
#     app: web

# Check if destination pod has label
kubectl get pod -n <namespace> <pod-name> --show-labels

# If missing label, add it:
kubectl label pod <pod-name> app=web -n <namespace>

# Or check from/to selectors don't match:
kubectl get networkpolicy -o yaml | grep -A 10 "from:"

# Verify source pods have matching labels
```

### Cause 4: Port Mismatch
```bash
# Check network policy ports
kubectl get networkpolicy <policy-name> -o yaml | grep -A 3 "ports"

# Example:
# ports:
# - protocol: TCP
#   port: 80

# Verify service is on that port
kubectl get svc <service-name> -o yaml | grep -A 3 "ports"

# If service on 8080 but policy allows 80:
# Either update policy to port 8080
# Or service to port 80
```

### Cause 5: Namespace Selector Issues
```bash
# Check if policy allows cross-namespace traffic
kubectl get networkpolicy <policy-name> -o yaml | grep -A 10 "from:"

# If using namespaceSelector:
# from:
# - namespaceSelector:
#     matchLabels:
#       name: allowed

# Verify source namespace has label
kubectl get ns <source-namespace> --show-labels

# If label missing, add it:
kubectl label ns <source-namespace> name=allowed
```

## Recovery Process
```bash
# 1. Check if network policies exist
kubectl get networkpolicy -A

# 2. Identify blocking policies
kubectl get networkpolicy -n <namespace> -o yaml

# 3. Understand the rules (from/to/ports)

# 4. Create allow policy for needed traffic
# or remove restrictive policy temporarily

# 5. Test connectivity again
kubectl run -it debug --image=curlimages/curl --rm -- curl http://<service>:80

# 6. If works, refine policy as needed
```

---

## Network Policy Issue: Traffic Incorrectly Allowed

**Symptoms:**
- Pod can reach service it shouldn't
- Security policy not enforcing
- Cross-namespace traffic allowed when shouldn't be

## Diagnosis
```bash
# Test from pod that shouldn't have access
kubectl run -it --name=restricted --image=curlimages/curl --rm -- curl http://<restricted-service>:80

# Check network policies
kubectl get networkpolicy -A

# Check if policy applies to source pod
kubectl get pod -n <namespace> --show-labels

# Compare with policy selector

# Check routes/DNS
kubectl run -it debug --image=curlimages/curl --rm -- nslookup <service>
```

## Common Issues & Fixes

### Issue: Policy Too Permissive
```bash
# Check policy ingress rules
kubectl get networkpolicy <policy-name> -o yaml | grep -A 15 "ingress:"

# Example too open:
# ingress:
# - from:
#   - podSelector: {}  # ← Allows from ANY pod

# Restrict to specific pods:
kubectl patch networkpolicy <policy-name> \
  -p '{"spec":{"ingress":[{"from":[{"podSelector":{"matchLabels":{"app":"web"}}}]}]}}' \
  -n <namespace>
```

### Issue: No Deny Policy Between Namespaces
```bash
# If cross-namespace access should be blocked

# Create default deny for ingress from other namespaces:
kubectl apply -f - <<EOF
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny-cross-ns
  namespace: secure-namespace
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          name: secure-namespace
EOF

# Add label to namespace
kubectl label ns secure-namespace name=secure-namespace
```

### Issue: Policy Not Applying
```bash
# Check if network plugin supports policies
kubectl get daemonset -n kube-system | grep -i "flannel\|calico\|weave"

# If no CNI plugin, policies don't work
# Flannel doesn't support NetworkPolicy (need Calico)

# Install Calico:
kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.26.1/manifests/tigera-operator.yaml

# Wait for installation
kubectl get pods -n tigera-operator

# Then policies will work
```

---

## DNS Issue: Pod Cannot Resolve Service Names

**Symptoms:**
- `nslookup <service-name>` fails in pod
- Pod cannot reach service by name (only by IP)
- DNS timeout or NXDOMAIN errors

## Quick Diagnosis
```bash
# Test DNS from pod
kubectl run -it debug --image=curlimages/curl --rm -- nslookup kubernetes

# Check coredns pods
kubectl get pods -n kube-system -l k8s-app=kube-dns
# or
kubectl get pods -n kube-system -l k8s-app=kube-dns
# or for newer versions:
kubectl get pods -n kube-system -l k8s-app=kube-dns

# Check coredns logs
kubectl logs -n kube-system -l k8s-app=kube-dns --tail=50

# Check service exists
kubectl get svc <service-name>

# Check search domain in pod
kubectl run -it debug --image=curlimages/curl --rm -- cat /etc/resolv.conf
```

## Common Causes & Fixes

### Cause 1: CoreDNS Pod Not Running
```bash
# Check CoreDNS status
kubectl get pods -n kube-system -l k8s-app=kube-dns

# If not running or CrashLoopBackOff:
kubectl describe pod -n kube-system <coredns-pod>

# Check logs
kubectl logs -n kube-system <coredns-pod>

# Restart if needed
kubectl delete pod -n kube-system <coredns-pod>

# Should auto-restart via deployment
```

### Cause 2: CoreDNS Not Ready
```bash
# Check pod readiness
kubectl get pods -n kube-system -l k8s-app=kube-dns -o wide

# If not ready, check events
kubectl describe pod -n kube-system <coredns-pod> | grep -A 10 Events

# Likely causes:
# - No endpoints for kubernetes service
# - RBAC permissions missing

# Verify kubernetes service exists
kubectl get svc kubernetes -n default
```

### Cause 3: CoreDNS ConfigMap Wrong
```bash
# Check CoreDNS config
kubectl get configmap coredns -n kube-system -o yaml

# Look for Corefile content
kubectl get configmap coredns -n kube-system -o yaml | grep -A 20 "Corefile:"

# Should include kubernetes zone:
# kubernetes cluster.local in-addr.arpa ip6.arpa {

# If missing, fix it:
kubectl edit configmap coredns -n kube-system

# Ensure has:
Corefile: |
  .:53 {
      errors
      health
      kubernetes cluster.local in-addr.arpa ip6.arpa {
        pods insecure
      }
      prometheus
      forward . /etc/resolv.conf
      cache 30
  }

# Restart pods
kubectl delete pod -n kube-system -l k8s-app=kube-dns
```

### Cause 4: Pod Not Configured for DNS
```bash
# Check if pod has dnsPolicy set
kubectl get pod <pod-name> -o jsonpath='{.spec.dnsPolicy}'

# Default is "ClusterFirst" which should use CoreDNS
# If "None", pod won't use cluster DNS

# Fix:
kubectl patch pod <pod-name> -p '{"spec":{"dnsPolicy":"ClusterFirst"}}'

# Note: Requires pod recreation if already running
```

### Cause 5: Firewall Blocking DNS (Port 53)
```bash
# Test DNS manually
kubectl run -it debug --image=busybox --rm -- sh
# Inside: nslookup kubernetes.default.svc.cluster.local 10.96.0.10

# If hangs, network policy might block port 53
# Check network policies
kubectl get networkpolicy -A

# Allow DNS port:
kubectl apply -f - <<EOF
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-dns
  namespace: kube-system
spec:
  podSelector:
    matchLabels:
      k8s-app: kube-dns
  policyTypes:
  - Ingress
  ingress:
  - ports:
    - protocol: UDP
      port: 53
EOF
```

## Recovery Process
```bash
# 1. Test DNS from debug pod
kubectl run -it debug --image=curlimages/curl --rm -- nslookup kubernetes

# 2. If fails, check CoreDNS status
kubectl get pods -n kube-system -l k8s-app=kube-dns

# 3. Check CoreDNS logs
kubectl logs -n kube-system -l k8s-app=kube-dns | tail -20

# 4. Verify kubernetes service exists
kubectl get svc kubernetes

# 5. Apply fix based on diagnosis

# 6. Restart CoreDNS if changed config
kubectl delete pod -n kube-system -l k8s-app=kube-dns

# 7. Test again
kubectl run -it debug --image=curlimages/curl --rm -- nslookup kubernetes
```

---

## Pod Network Connectivity Issues

**Symptoms:**
- Pod cannot reach external network/internet
- Pod cannot reach pod on different node
- Pod can reach service but not backing pods

## Diagnosis
```bash
# Test connectivity from pod
kubectl run -it debug --image=curlimages/curl --rm -- sh

# Inside pod:
# Check default gateway
route

# Try to reach service
curl http://<service-ip>:80

# Try to reach pod IP directly
curl http://<pod-ip>:80

# Try external
curl http://8.8.8.8

# Check pod's network interface
ip addr
ip route
```

## Common Issues & Fixes

### Issue: No CNI Plugin Installed
```bash
# Check if CNI plugin deployed
kubectl get daemonset -n kube-system

# Look for flannel, calico, weave, etc.
# If none, networking won't work

# Install Flannel:
kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml

# Wait for deployment
kubectl get pods -n kube-system | grep flannel

# Then test pod networking
```

### Issue: Pod Network Different from Node
```bash
# Check pod CIDR
kubectl cluster-info dump | grep -i "cluster-cidr\|pod-cidr"

# Check node CIDR
kubectl get node <node> -o yaml | grep podCIDR

# Should match

# Check kubelet logs
ssh <node>
sudo journalctl -u kubelet | grep -i "cidr"

# If CIDR not assigned to node, restart kubelet
sudo systemctl restart kubelet
```

### Issue: MTU Size Causing Packet Loss
```bash
# Check pod network MTU
kubectl run -it debug --image=curlimages/curl --rm -- ip link

# Should show: mtu 1450 or similar

# If issues with large files, might be MTU problem

# Check CNI plugin config
kubectl get daemonset <cni-plugin> -o yaml | grep -i mtu

# Adjust if needed (common: 1450 for flannel)
```

---

## Quick Reference: Networking Issues

| Issue | Diagnosis | Common Fix |
|-------|-----------|-----------|
| Network policy blocks traffic | `kubectl get networkpolicy` | Create allow policy |
| DNS not resolving | `nslookup <service>` | Restart CoreDNS or fix config |
| Service unreachable | `kubectl get endpoints` | Fix service selector |
| Port-forward fails | `curl localhost:port` | Fix service selector or start pods |
| Pod can't reach external | `traceroute 8.8.8.8` | Install CNI plugin |
| DNS timeout | `kubectl logs kube-dns` | Check CoreDNS ConfigMap |

---

## CKA Exam Tips

- **Network policies**: Default allow all (unless restrictive policy exists)
- **Ingress vs Egress**: Separate policy types, must specify explicitly
- **podSelector vs namespaceSelector**: Can combine with AND logic in from/to
- **DNS is UDP port 53**: Very important for troubleshooting
- **CoreDNS**: Standard in modern Kubernetes, replaced kube-dns
- **Service discovery**: Uses <service>.<namespace>.svc.cluster.local FQDN
- **Network plugins**: Flannel, Calico, Weave - plugins handle actual networking
- **Quick test**: `kubectl run -it debug --rm -- curl` is your friend

---

## See Also
- Pod troubleshooting scenarios (for network-related pod issues)
- Service configuration and endpoints
- Ingress controller setup and troubleshooting
- Load balancer and external service issues
