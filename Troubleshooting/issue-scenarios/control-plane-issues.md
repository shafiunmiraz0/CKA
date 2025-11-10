# Control Plane Troubleshooting Scenarios

## Common Control Plane Issues

### 1. API Server Issues
**Symptoms:**
- kubectl commands not responding
- API server not accessible
- Certificate errors

**Debugging Steps:**
```bash
# Check API server pod status
kubectl get pods -n kube-system -l component=kube-apiserver

# Check API server logs
kubectl logs -n kube-system -l component=kube-apiserver

# Check API server certificate
openssl x509 -in /etc/kubernetes/pki/apiserver.crt -text -noout
```

### 2. Controller Manager Issues
**Symptoms:**
- Resources not being reconciled
- Controller not processing events
- Deployments/Services not updating

**Debugging Steps:**
```bash
# Check controller manager status
kubectl get pods -n kube-system -l component=kube-controller-manager

# View controller manager logs
kubectl logs -n kube-system -l component=kube-controller-manager

# Check leader election
kubectl get endpoints kube-controller-manager -n kube-system -o yaml
```

### 3. Scheduler Issues
**Symptoms:**
- Pods stuck in Pending state
- Scheduling decisions not being made
- Node allocation issues

**Debugging Steps:**
```bash
# Check scheduler pod
kubectl get pods -n kube-system -l component=kube-scheduler

# View scheduler logs
kubectl logs -n kube-system -l component=kube-scheduler

# Check node conditions
kubectl describe nodes | grep -A 5 Conditions
```

### 4. ETCD Issues
**Symptoms:**
- Cluster state inconsistencies
- API server errors
- Slow operations

**Debugging Steps:**
```bash
# Check ETCD pod/process
kubectl get pods -n kube-system -l component=etcd

# Check ETCD health
ETCDCTL_API=3 etcdctl --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key \
  endpoint health

# Backup ETCD
ETCDCTL_API=3 etcdctl --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key \
  snapshot save snapshot.db
```

## Quick Reference Commands

```bash
# Check control plane pods
kubectl get pods -n kube-system

# Get component status
kubectl get componentstatuses

# Check all control plane logs
kubectl logs -n kube-system -l tier=control-plane

# Check certificates
kubeadm certs check-expiration

# Check API server health
curl -k https://localhost:6443/healthz

# View cluster events
kubectl get events -n kube-system
```

## Common Control Plane Configurations

### 1. API Server Configuration
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: kube-apiserver
  namespace: kube-system
spec:
  containers:
  - command:
    - kube-apiserver
    - --advertise-address=192.168.1.10
    - --allow-privileged=true
    - --authorization-mode=Node,RBAC
    - --client-ca-file=/etc/kubernetes/pki/ca.crt
    - --enable-admission-plugins=NodeRestriction
    - --enable-bootstrap-token-auth=true
    - --etcd-cafile=/etc/kubernetes/pki/etcd/ca.crt
    - --etcd-certfile=/etc/kubernetes/pki/apiserver-etcd-client.crt
    - --etcd-keyfile=/etc/kubernetes/pki/apiserver-etcd-client.key
    - --etcd-servers=https://127.0.0.1:2379
    image: k8s.gcr.io/kube-apiserver:v1.21.0
    name: kube-apiserver
```

### 2. ETCD Backup and Restore
```bash
# Backup ETCD
ETCDCTL_API=3 etcdctl snapshot save snapshot.db \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key

# Restore ETCD
ETCDCTL_API=3 etcdctl snapshot restore snapshot.db \
  --data-dir /var/lib/etcd-backup \
  --initial-cluster="master=https://127.0.0.1:2380" \
  --initial-cluster-token="etcd-cluster-1" \
  --initial-advertise-peer-urls="https://127.0.0.1:2380"
```

### 3. Control Plane Health Check Script
```bash
#!/bin/bash
# Check API Server
echo "Checking API Server..."
kubectl get --raw='/healthz'

# Check ETCD
echo "Checking ETCD..."
ETCDCTL_API=3 etcdctl endpoint health \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key

# Check Controller Manager
echo "Checking Controller Manager..."
kubectl get pods -n kube-system -l component=kube-controller-manager

# Check Scheduler
echo "Checking Scheduler..."
kubectl get pods -n kube-system -l component=kube-scheduler
```