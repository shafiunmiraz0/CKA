# Backup and Restore Troubleshooting Scenarios

## Common Backup & Restore Issues

### 1. ETCD Backup Issues
**Symptoms:**
- Backup creation failure
- Corrupted backup files
- Certificate-related backup errors

**Debugging Steps:**
```bash
# Verify ETCD health
ETCDCTL_API=3 etcdctl endpoint health \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key

# Check ETCD member list
ETCDCTL_API=3 etcdctl member list \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key

# Verify backup file
ls -l snapshot.db
sha256sum snapshot.db
```

### 2. ETCD Restore Issues
**Symptoms:**
- Restore process fails
- Cluster state inconsistency
- API server communication issues

**Debugging Steps:**
```bash
# Verify backup file integrity
ETCDCTL_API=3 etcdctl snapshot status snapshot.db

# Check restore target
df -h /var/lib/etcd
ls -l /var/lib/etcd

# Verify ETCD service
systemctl status etcd
journalctl -u etcd
```

### 3. Resource Restore Issues
**Symptoms:**
- Missing resources after restore
- Resource version conflicts
- Namespace restoration problems

**Debugging Steps:**
```bash
# Check resource status
kubectl get all --all-namespaces

# Verify resource versions
kubectl get <resource> -o yaml

# Check events
kubectl get events --sort-by='.metadata.creationTimestamp'
```

## Common Backup & Restore Commands

### 1. ETCD Backup
```bash
# Full backup command
ETCDCTL_API=3 etcdctl snapshot save snapshot.db \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key

# Verify backup
ETCDCTL_API=3 etcdctl snapshot status snapshot.db

# Resource backup
kubectl get all --all-namespaces -o yaml > cluster-backup.yaml
```

### 2. ETCD Restore
```bash
# Stop kube-apiserver
systemctl stop kube-apiserver

# Restore from snapshot
ETCDCTL_API=3 etcdctl snapshot restore snapshot.db \
  --data-dir=/var/lib/etcd-restore \
  --name=master \
  --initial-cluster=master=https://127.0.0.1:2380 \
  --initial-cluster-token=etcd-cluster-1 \
  --initial-advertise-peer-urls=https://127.0.0.1:2380

# Update ETCD configuration
mv /var/lib/etcd-restore/* /var/lib/etcd/

# Restart services
systemctl restart etcd
systemctl restart kube-apiserver
```

### 3. Resource Restore
```bash
# Restore specific resources
kubectl apply -f cluster-backup.yaml

# Restore with server-side apply
kubectl apply -f cluster-backup.yaml --server-side

# Selective restore
kubectl apply -f cluster-backup.yaml -l app=critical
```

## Best Practices

### 1. Regular Backup Schedule
```bash
# Create a CronJob for ETCD backup
apiVersion: batch/v1
kind: CronJob
metadata:
  name: etcd-backup
spec:
  schedule: "0 */6 * * *"
  jobTemplate:
    spec:
      template:
        spec:
          containers:
          - name: etcd-backup
            image: k8s.gcr.io/etcd:3.5.1-0
            command:
            - /bin/sh
            - -c
            - |
              ETCDCTL_API=3 etcdctl snapshot save /backup/etcd-snapshot-$(date +%Y%m%d-%H%M%S).db \
                --endpoints=https://127.0.0.1:2379 \
                --cacert=/etc/kubernetes/pki/etcd/ca.crt \
                --cert=/etc/kubernetes/pki/etcd/server.crt \
                --key=/etc/kubernetes/pki/etcd/server.key
            volumeMounts:
            - name: etcd-certs
              mountPath: /etc/kubernetes/pki/etcd
              readOnly: true
            - name: backup
              mountPath: /backup
          volumes:
          - name: etcd-certs
            hostPath:
              path: /etc/kubernetes/pki/etcd
              type: Directory
          - name: backup
            hostPath:
              path: /var/etcd-backup
              type: DirectoryOrCreate
          restartPolicy: OnFailure
```

### 2. Pre-Restore Checks
```bash
# Verify cluster health
kubectl get componentstatuses
kubectl get nodes
kubectl get pods --all-namespaces

# Check ETCD member status
ETCDCTL_API=3 etcdctl endpoint health --cluster

# Backup current state
cp -r /var/lib/etcd /var/lib/etcd-backup
```

### 3. Post-Restore Verification
```bash
# Verify cluster functionality
kubectl get nodes
kubectl get pods --all-namespaces
kubectl get svc --all-namespaces

# Check control plane components
kubectl get pods -n kube-system
kubectl logs -n kube-system kube-apiserver-master

# Verify critical workloads
kubectl get deployments --all-namespaces
kubectl get statefulsets --all-namespaces
```