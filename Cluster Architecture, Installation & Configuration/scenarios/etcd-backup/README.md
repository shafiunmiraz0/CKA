# ETCD Backup Scenario

## Scenario Description
You need to create a backup of the etcd database in a Kubernetes cluster.

## Requirements
1. Create a snapshot of the etcd database
2. Save the backup to a specific location
3. Verify the backup file exists and is valid

## Solution

### 1. Locate ETCD Pod and Certificates
```bash
# Find the etcd pod in kube-system namespace
kubectl get pods -n kube-system | grep etcd

# Check the location of etcd certificates (usually in /etc/kubernetes/pki/etcd/)
ls -l /etc/kubernetes/pki/etcd/
```

### 2. Create ETCD Snapshot
```bash
# Using etcdctl command
ETCDCTL_API=3 etcdctl snapshot save /tmp/etcd-backup.db \
--endpoints=https://127.0.0.1:2379 \
--cacert=/etc/kubernetes/pki/etcd/ca.crt \
--cert=/etc/kubernetes/pki/etcd/server.crt \
--key=/etc/kubernetes/pki/etcd/server.key
```

### 3. Verify Backup
```bash
# Check if backup file exists
ls -lh /tmp/etcd-backup.db

# Verify the backup
ETCDCTL_API=3 etcdctl snapshot status /tmp/etcd-backup.db --write-out=table
```

## Important Notes
1. Always ensure you have enough disk space for the backup
2. Keep track of the Kubernetes version when taking backups
3. Store backups in a secure location
4. Regular backup schedule is recommended
5. Document the backup procedure and location

## Common Issues and Solutions
1. Certificate paths might be different in your cluster
2. Ensure proper permissions to access certificates
3. Verify endpoint availability
4. Check disk space before backup

## Verification
```bash
# The backup command should output something like:
Snapshot saved at /tmp/etcd-backup.db

# Status command should show:
Hash: xxxx
Revision: xxxx
Total Keys: xxxx
Total Size: xxxx MB
```