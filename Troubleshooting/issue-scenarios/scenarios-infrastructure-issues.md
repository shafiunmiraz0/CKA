# Node and Kubelet Troubleshooting Scenarios

## Node Issue: Node Not Ready

**Symptoms:**
- Node status shows `NotReady`
- Pods on node are evicted or pending
- Cannot schedule new pods to node
- Node age high but status stuck

## Quick Diagnosis
```bash
# Check node status
kubectl get nodes
# Output: <node>   NotReady   ...

# Detailed node info
kubectl describe node <node-name>

# Check node conditions
kubectl get node <node-name> -o jsonpath='{.status.conditions}' | jq .

# Expected output:
# MemoryPressure: False
# DiskPressure: False
# PIDPressure: False
# Ready: False  (← Problem)
```

## Common Causes & Fixes

### Cause 1: Kubelet Not Running
```bash
# SSH to node
ssh <node>

# Check kubelet status
sudo systemctl status kubelet

# If not running, start it
sudo systemctl start kubelet
sudo systemctl enable kubelet

# Verify service started
sudo systemctl is-active kubelet

# Check logs
sudo journalctl -u kubelet -n 50
```

### Cause 2: Kubelet Crashed or High Memory
```bash
# Check kubelet logs for crashes
sudo journalctl -u kubelet | grep -i "crash\|panic\|fatal"

# Check kubelet process
ps aux | grep kubelet

# If crashed, restart
sudo systemctl restart kubelet

# Monitor logs
sudo journalctl -u kubelet -f
```

### Cause 3: Insufficient Disk Space
```bash
# SSH to node and check disk
ssh <node>
df -h

# If /var/lib/kubelet is full:
sudo du -sh /var/lib/kubelet

# Clean up old container images
sudo docker system prune -a
# or
sudo crictl rmi --prune

# Clear journal logs
sudo journalctl --vacuum=100M
```

### Cause 4: Certificate Expiry
```bash
# Check kubelet certificate expiry
sudo openssl x509 -in /var/lib/kubelet/pki/kubelet-client-current.pem -noout -dates

# If expired, certificate renewal needed (depends on your setup)
# Usually automatic in modern Kubernetes
```

### Cause 5: Container Runtime Issues
```bash
# SSH to node
ssh <node>

# Check Docker/Containerd
sudo systemctl status docker
# or
sudo systemctl status containerd

# If not running, restart
sudo systemctl restart docker
# or
sudo systemctl restart containerd

# Verify container runtime health
docker ps
# or
crictl ps
```

## Recovery Process
```bash
# After fixing kubelet/runtime on node:
# 1. Verify kubelet is running
sudo systemctl is-active kubelet

# 2. Check node status from master
kubectl get nodes

# 3. Monitor node recovery
watch 'kubectl describe node <node> | grep -A 5 Conditions'

# 4. Eventually should show:
# Ready True
```

---

## Kubelet Issue: Certificate Expiry

**Symptoms:**
- Kubelet logs show "certificate has expired"
- kubectl commands timeout
- New nodes cannot join

## Diagnosis
```bash
# Check kubelet certificate dates
ssh <node>
sudo openssl x509 -in /var/lib/kubelet/pki/kubelet-client-current.pem -noout -dates

# Output should show:
# notBefore=Jan 1 10:00:00 2024 GMT
# notAfter=Jan 1 10:00:00 2025 GMT  (if expired, this is in past)

# Check kubelet logs
sudo journalctl -u kubelet | grep -i "certificate\|expired"
```

## Fix: Rotate Certificates
```bash
# On master node
sudo kubeadm certs renew all

# Verify renewed
sudo kubeadm certs check-expiration

# Restart kubelet on master
sudo systemctl restart kubelet

# Restart kubelet on all worker nodes
ssh <worker-node>
sudo systemctl restart kubelet
```

---

## Controller Manager and API Server Issues

**Symptoms:**
- API server not responding
- kubectl commands hang or timeout
- Deployments/pods not being reconciled
- Kube-controller-manager not working

## Quick Diagnosis
```bash
# Check control plane pods
kubectl get pods -n kube-system -l component=kube-apiserver
kubectl get pods -n kube-system -l component=kube-controller-manager

# Check if pods running
kubectl describe pod -n kube-system <pod-name>

# Check pod logs
kubectl logs -n kube-system <pod-name> --tail=50

# Check readiness
kubectl get pods -n kube-system -l component=kube-apiserver -o jsonpath='{.items[0].status.conditions}' | jq .
```

## Common Issues & Fixes

### Issue: API Server OOMKilled
```bash
# Check pod events
kubectl describe pod -n kube-system <api-server-pod>
# Shows: "OOMKilled" or "memory limit exceeded"

# Increase memory limit in static pod manifest
ssh <master>
sudo nano /etc/kubernetes/manifests/kube-apiserver.yaml

# Find resources section:
# resources:
#   requests:
#     memory: "256Mi"
#   limits:
#     memory: "512Mi"

# Increase to:
resources:
  requests:
    memory: "1Gi"
  limits:
    memory: "2Gi"

# Save and exit (kubelet auto-restarts pod)
```

### Issue: High Latency from API Server
```bash
# Check API server logs
kubectl logs -n kube-system <api-server-pod> --tail=100 | grep -i "latency\|slow"

# Check etcd status
kubectl get pods -n kube-system -l component=etcd

# Check etcd logs
kubectl logs -n kube-system <etcd-pod> --tail=50

# If etcd slow, it cascades to API server

# Restart etcd
ssh <master>
sudo systemctl restart etcd
# or
sudo crictl restart <etcd-container-id>
```

---

## ETCD Backup and Restore Issues

**Scenario: ETCD Backup**
```bash
# SSH to etcd node (usually master)
ssh <master>

# Take snapshot
sudo ETCDCTL_API=3 etcdctl \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key \
  snapshot save /tmp/etcd-backup.db

# Verify backup
sudo ETCDCTL_API=3 etcdctl \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key \
  snapshot status /tmp/etcd-backup.db
```

**Scenario: ETCD Restore**
```bash
# Stop API server and kubelet
sudo systemctl stop kubelet
sudo mv /etc/kubernetes/manifests /etc/kubernetes/manifests.bak

# Wait for API server to stop
sleep 10

# Restore etcd
sudo ETCDCTL_API=3 etcdctl \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key \
  snapshot restore /tmp/etcd-backup.db \
  --data-dir=/var/lib/etcd-backup

# Update data directory
sudo mv /var/lib/etcd /var/lib/etcd-old
sudo mv /var/lib/etcd-backup /var/lib/etcd

# Restart kubelet and API server
sudo mv /etc/kubernetes/manifests.bak /etc/kubernetes/manifests
sudo systemctl start kubelet

# Wait for restart
sleep 30

# Verify cluster recovered
kubectl get nodes
kubectl get pods -A
```

---

## Network and Proxy Issues

**Kubectl Config Issue:**
```bash
# Problem: kubectl cannot connect
kubectl get nodes
# Error: Unable to connect to the server

# Check kubeconfig
cat ~/.kube/config

# Verify server address is correct
grep server: ~/.kube/config

# Check if API server is running
kubectl get pods -n kube-system -l component=kube-apiserver

# Verify context
kubectl config current-context

# If wrong context:
kubectl config use-context <correct-context>
```

**Kubectl Port Issue:**
```bash
# Problem: kubectl connects but port 6443 unreachable

# Check API server service
kubectl get svc -n default
kubectl get svc kubernetes

# Verify API server listening
netstat -tlnp | grep 6443

# If not listening, check if API server pod is running
kubectl get pods -n kube-system -l component=kube-apiserver

# Check pod logs
kubectl logs -n kube-system <api-server-pod>
```

---

## Kube-Proxy Issues

**Symptoms:**
- Services not reachable
- LoadBalancer ports not working
- DNS not resolving

## Diagnosis
```bash
# Check kube-proxy pods
kubectl get pods -n kube-system -l k8s-app=kube-proxy

# Check kube-proxy logs
kubectl logs -n kube-system -l k8s-app=kube-proxy --tail=50

# Check if iptables rules created
sudo iptables -L -n | grep <service-ip>

# Check ipvs rules (if using ipvs mode)
sudo ipvsadm -L -n
```

## Common Issues & Fixes

### Issue: Kube-Proxy CrashLoopBackOff
```bash
# Check pod events
kubectl describe pod -n kube-system <kube-proxy-pod>

# Often due to incompatible kernel or wrong mode
# Force ipvs or iptables mode

# Check current mode
kubectl logs -n kube-system -l k8s-app=kube-proxy | grep -i "mode\|proxier"

# Update ConfigMap if needed
kubectl edit configmap -n kube-system kube-proxy
# Change mode: iptables to mode: ipvs (or vice versa)

# Restart kube-proxy
kubectl delete pod -n kube-system -l k8s-app=kube-proxy
```

---

## Quick Reference: Infrastructure Issues

| Issue | Command to Check | Fix |
|-------|------------------|-----|
| Node Not Ready | `kubectl describe node` | SSH and restart kubelet |
| Kubelet Down | `sudo systemctl status kubelet` | `sudo systemctl start kubelet` |
| Disk Full | `ssh <node> && df -h` | Clean docker images, journalctl |
| Cert Expired | `sudo openssl x509 ... -dates` | `kubeadm certs renew all` |
| API Server Down | `kubectl logs -n kube-system <pod>` | Check pod logs, increase memory |
| Etcd Issues | `kubectl logs -n kube-system <etcd>` | Restart etcd or restore backup |
| Kube-Proxy Down | `kubectl logs -n kube-system <proxy>` | Change mode or restart |
| Cannot Connect | `grep server: ~/.kube/config` | Verify server address |

---

## CKA Exam Tips

- **Master node first**: Always check master/control plane health first
- **Systemctl commands crucial**: Know `systemctl status/restart/enable`
- **Logs are your friend**: `kubectl logs` and `journalctl` show most issues
- **Certificate rotation**: `kubeadm certs` commands important for 1.24+
- **Kubelet restarts static pods**: Changes to `/etc/kubernetes/manifests/` auto-restart
- **ETCD snapshots**: Know backup/restore for disaster recovery
- **Quick triage**: `kubectl get nodes`, `kubectl get pods -n kube-system` show overall health

---

## See Also
- Pod troubleshooting scenarios
- Deployment troubleshooting
- Network policy issues
- Service account and RBAC issues
