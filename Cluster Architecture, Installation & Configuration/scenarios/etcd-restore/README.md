# ETCD Restore Scenario

## Scenario Description
You need to restore an etcd database from a backup in a Kubernetes cluster.

## Requirements
1. Stop the API server
2. Restore etcd from the backup file
3. Restart the cluster components
4. Verify the restore was successful

## Solution

### 1. Prepare for Restore
```bash
# Stop kube-apiserver
sudo -i
cd /etc/kubernetes/manifests/
mv kube-apiserver.yaml ..

# Verify apiserver is stopped
kubectl get pods -n kube-system  # Should fail
```

### 2. Restore from Backup
```bash
# Restore using etcdctl
ETCDCTL_API=3 etcdctl snapshot restore /tmp/etcd-backup.db \
--data-dir=/var/lib/etcd-restore \
--initial-cluster="master-node=https://127.0.0.1:2380" \
--initial-advertise-peer-urls="https://127.0.0.1:2380" \
--name=master-node
```

### 3. Update ETCD Configuration
```bash
# Update etcd.yaml to use new data directory
# Edit /etc/kubernetes/manifests/etcd.yaml
# Change --data-dir to /var/lib/etcd-restore
```

### 4. Restart Services
```bash
# Move API server manifest back
mv ../kube-apiserver.yaml /etc/kubernetes/manifests/

# Restart kubelet
systemctl restart kubelet
```

## Important Notes
1. Always take a new backup before restore
2. Ensure cluster is not in use during restore
3. Document all steps taken
4. Have a rollback plan
5. Test restore procedure regularly

## Common Issues and Solutions
1. API server not starting after restore
   - Check logs: journalctl -u kubelet -f
   - Verify certificate paths
2. ETCD fails to start with new data directory
   - Check permissions
   - Verify paths in manifests
3. Cluster state inconsistencies
   - May need to recreate some resources
   - Check resource versions

## Verification
```bash
# Check cluster health
kubectl get nodes
kubectl get pods --all-namespaces

# Verify ETCD health
ETCDCTL_API=3 etcdctl endpoint health \
--endpoints=https://127.0.0.1:2379 \
--cacert=/etc/kubernetes/pki/etcd/ca.crt \
--cert=/etc/kubernetes/pki/etcd/server.crt \
--key=/etc/kubernetes/pki/etcd/server.key
```