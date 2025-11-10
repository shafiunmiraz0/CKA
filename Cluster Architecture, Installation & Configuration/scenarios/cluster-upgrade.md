# Cluster Upgrade Scenario

## Scenario Description
Upgrade a Kubernetes cluster from version 1.26.x to 1.27.x while ensuring minimal downtime.

## Requirements
1. Upgrade kubeadm
2. Drain nodes properly
3. Upgrade control plane components
4. Upgrade worker nodes
5. Verify cluster health

## Solution

### 1. Control Plane Node Upgrade
```bash
# Check current version
kubectl get nodes

# Drain control plane node
kubectl drain <cp-node-name> --ignore-daemonsets

# Update kubeadm
apt update
apt-cache madison kubeadm
apt install kubeadm=1.27.x-00

# Plan the upgrade
kubeadm upgrade plan

# Apply the upgrade
kubeadm upgrade apply v1.27.x

# Upgrade kubelet and kubectl
apt install kubelet=1.27.x-00 kubectl=1.27.x-00
systemctl daemon-reload
systemctl restart kubelet

# Uncordon the node
kubectl uncordon <cp-node-name>
```

### 2. Worker Nodes Upgrade
```bash
# On each worker node:

# Drain the node
kubectl drain <worker-node-name> --ignore-daemonsets

# Update kubeadm
apt update
apt install kubeadm=1.27.x-00

# Upgrade node
kubeadm upgrade node

# Upgrade kubelet and kubectl
apt install kubelet=1.27.x-00 kubectl=1.27.x-00
systemctl daemon-reload
systemctl restart kubelet

# Uncordon the node
kubectl uncordon <worker-node-name>
```

## Important Notes
1. Always backup etcd before upgrade
2. Check for workload disruption
3. Follow the upgrade order:
   - Control plane components
   - Control plane node kubelet
   - Worker nodes
4. Test upgrade procedure on test cluster first
5. Have a rollback plan ready

## Common Issues and Solutions
1. Pod eviction timeout
   - Increase eviction timeout
   - Force delete stuck pods
2. Node not ready after upgrade
   - Check kubelet status
   - Verify certificates
3. Version skew issues
   - Follow supported version skew policy
   - Upgrade one minor version at a time

## Verification
```bash
# Check node versions
kubectl get nodes

# Verify cluster health
kubectl get pods -A
kubectl cluster-info

# Check component status
kubectl get componentstatuses
```

## Rollback Procedure
```bash
# If needed, you can rollback:
kubeadm rollback
apt install kubelet=1.26.x-00 kubectl=1.26.x-00
systemctl restart kubelet
```