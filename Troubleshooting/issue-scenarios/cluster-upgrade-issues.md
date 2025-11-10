# Cluster Upgrade Troubleshooting Scenarios

## Common Cluster Upgrade Issues

### 1. Version Skew Issues
**Symptoms:**
- Component version mismatch
- API version compatibility errors
- Node communication issues

**Debugging Steps:**
```bash
# Check component versions
kubectl version --short
kubectl get nodes -o wide
kubelet --version

# Verify control plane versions
kubectl get pods -n kube-system -o custom-columns=NAME:.metadata.name,IMAGE:.spec.containers[0].image

# Check API versions support
kubectl api-versions
kubectl api-resources
```

### 2. Upgrade Process Issues
**Symptoms:**
- Control plane upgrade failure
- Node upgrade stuck
- Workload disruption

**Debugging Steps:**
```bash
# Check upgrade plan
kubeadm upgrade plan

# Verify control plane health
kubectl get componentstatuses
kubectl get pods -n kube-system

# Check node drain status
kubectl get nodes
kubectl describe node <node-name>
```

**Example Upgrade Commands:**
```bash
# Control plane upgrade
kubeadm upgrade apply v1.26.x

# Node upgrade
# 1. Drain node
kubectl drain <node-name> --ignore-daemonsets

# 2. Upgrade kubelet and kubeadm
apt-get update
apt-get install -y kubelet=1.26.x-00 kubeadm=1.26.x-00

# 3. Restart kubelet
systemctl daemon-reload
systemctl restart kubelet

# 4. Uncordon node
kubectl uncordon <node-name>
```

### 3. Post-Upgrade Issues
**Symptoms:**
- API deprecation warnings
- Workload compatibility issues
- Feature gate problems

**Debugging Steps:**
```bash
# Check for deprecated APIs
kubectl get --raw /metrics | grep deprecated

# Verify workload status
kubectl get all --all-namespaces

# Check feature gates
kubectl describe nodes | grep Feature
```

## Common Upgrade Scenarios

### 1. Control Plane Component Upgrade
```bash
# Upgrade sequence
kubeadm upgrade plan
kubeadm upgrade apply v1.26.x
kubectl drain <cp-node> --ignore-daemonsets
apt-get update && apt-get install -y kubeadm=1.26.x-00 kubelet=1.26.x-00 kubectl=1.26.x-00
systemctl daemon-reload
systemctl restart kubelet
kubectl uncordon <cp-node>
```

### 2. Worker Node Rolling Upgrade
```bash
# For each worker node
kubectl drain <node> --ignore-daemonsets
ssh <node>
apt-get update && apt-get install -y kubelet=1.26.x-00 kubeadm=1.26.x-00
kubeadm upgrade node
systemctl restart kubelet
exit
kubectl uncordon <node>
```

### 3. Version Verification
```bash
# Version check commands
kubectl version --short
kubectl get nodes -o wide
kubelet --version
kubeadm version

# API version verification
kubectl api-versions
kubectl convert -f old-deployment.yaml --output-version apps/v1
```

## Quick Reference Commands

```bash
# Pre-upgrade checks
kubeadm upgrade plan
kubectl drain <node> --ignore-daemonsets

# Version checks
kubectl version
kubelet --version
kubeadm version

# Post-upgrade verification
kubectl get nodes -o wide
kubectl get componentstatuses
kubectl get pods -n kube-system
```

## Best Practices

1. Always backup etcd before upgrade:
```bash
ETCDCTL_API=3 etcdctl snapshot save snapshot.db \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key
```

2. Check workload compatibility:
```bash
# Test workload on new version
kubectl create -f workload.yaml --dry-run=server
```

3. Verify CNI plugin compatibility:
```bash
# Check CNI version
kubectl describe daemonset -n kube-system calico-node
```