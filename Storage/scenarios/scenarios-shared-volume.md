# Shared Volumes (ReadWriteMany) — Scenarios & Commands

## Overview
**Shared Volumes (ReadWriteMany / RWX)** allow multiple Pods on different nodes to read and write to the same PersistentVolume simultaneously. This requires a provisioner/storage backend that supports RWX access mode.

---

## Scenario 1: NFS-Based Shared Volume

**Task**: Set up a shared volume using NFS provisioner for multiple Pods.

### Prerequisites
```bash
# Verify NFS provisioner is available
kubectl get storageclass

# Look for provisioner with NFS support (e.g., nfs.csi.k8s.io)

# Or use existing NFS class
kubectl describe sc nfs
```

### YAML Setup
```yaml
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: shared-storage
spec:
  accessModes:
    - ReadWriteMany       # Multiple Pods can mount
  resources:
    requests:
      storage: 10Gi
  storageClassName: nfs   # NFS provisioner

---
# Pod 1: Writer
apiVersion: v1
kind: Pod
metadata:
  name: writer-pod
spec:
  containers:
  - name: writer
    image: busybox
    command: ["/bin/sh", "-c"]
    args:
      - |
        while true; do
          echo "Writer: $(date): $(hostname)" >> /shared/output.txt
          sleep 2
        done
    volumeMounts:
    - mountPath: /shared
      name: shared-vol
  volumes:
  - name: shared-vol
    persistentVolumeClaim:
      claimName: shared-storage
  nodeSelector:
    kubernetes.io/hostname: node1  # Run on node1

---
# Pod 2: Reader on different node
apiVersion: v1
kind: Pod
metadata:
  name: reader-pod
spec:
  containers:
  - name: reader
    image: busybox
    command: ["/bin/sh", "-c"]
    args:
      - |
        sleep 2
        while true; do
          echo "=== $(date) ==="
          cat /shared/output.txt
          sleep 5
        done
    volumeMounts:
    - mountPath: /shared
      name: shared-vol
  volumes:
  - name: shared-vol
    persistentVolumeClaim:
      claimName: shared-storage
  nodeSelector:
    kubernetes.io/hostname: node2  # Run on node2

---
# Pod 3: Another reader on yet another node
apiVersion: v1
kind: Pod
metadata:
  name: reader-pod-2
spec:
  containers:
  - name: reader
    image: busybox
    command: ["/bin/sh", "-c"]
    args:
      - |
        sleep 2
        while true; do
          echo "[Reader2] Files in /shared:"
          ls -la /shared/
          sleep 10
        done
    volumeMounts:
    - mountPath: /shared
      name: shared-vol
  volumes:
  - name: shared-vol
    persistentVolumeClaim:
      claimName: shared-storage
  nodeSelector:
    kubernetes.io/hostname: node3  # Run on node3
```

### Commands
```bash
# Create PVC with RWX access mode
kubectl apply -f shared-volume.yaml

# Verify PVC is Bound
kubectl get pvc shared-storage

# Check access mode is RWX
kubectl describe pvc shared-storage | grep "Access Modes"

# Create all Pods
kubectl apply -f writer-pod.yaml
kubectl apply -f reader-pod.yaml
kubectl apply -f reader-pod-2.yaml

# Verify all Pods running on different nodes
kubectl get pods -o wide

# Check logs from writer
kubectl logs writer-pod | head -10

# Check logs from readers (should see writer's output)
kubectl logs reader-pod | head -10
kubectl logs reader-pod-2 | head -10

# All Pods should see the same shared file!
```

### Verification
```bash
# Writer is writing to /shared/output.txt on all nodes via NFS
# Readers on different nodes see the same file content
# This proves NFS shared volume is working

# Example logs:
# Writer outputs:
# Writer: Mon Dec 5 10:00:00 UTC 2024: writer-pod
# Writer: Mon Dec 5 10:00:02 UTC 2024: writer-pod
# ...

# Readers see same content:
# Mon Dec 5 10:00:00 UTC 2024: writer-pod
# Mon Dec 5 10:00:02 UTC 2024: writer-pod
# ...
```

---

## Scenario 2: Multiple Pods with Write Access

**Task**: Have multiple Pods write to the same shared volume simultaneously.

### YAML
```yaml
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: shared-logs
spec:
  accessModes:
    - ReadWriteMany
  resources:
    requests:
      storage: 20Gi
  storageClassName: nfs

---
# Pod 1
apiVersion: v1
kind: Pod
metadata:
  name: app-pod-1
spec:
  containers:
  - name: app
    image: busybox
    command: ["/bin/sh", "-c"]
    args:
      - |
        for i in {1..5}; do
          echo "[App1-$(hostname)] Entry $i: $(date)" >> /logs/app1.log
          sleep 1
        done
        # Also write to shared log
        echo "[App1] Completed at $(date)" >> /logs/shared.log
        sleep 3600
    volumeMounts:
    - mountPath: /logs
      name: shared-logs
  volumes:
  - name: shared-logs
    persistentVolumeClaim:
      claimName: shared-logs

---
# Pod 2
apiVersion: v1
kind: Pod
metadata:
  name: app-pod-2
spec:
  containers:
  - name: app
    image: busybox
    command: ["/bin/sh", "-c"]
    args:
      - |
        for i in {1..5}; do
          echo "[App2-$(hostname)] Entry $i: $(date)" >> /logs/app2.log
          sleep 1
        done
        # Also write to shared log
        echo "[App2] Completed at $(date)" >> /logs/shared.log
        sleep 3600
    volumeMounts:
    - mountPath: /logs
      name: shared-logs
  volumes:
  - name: shared-logs
    persistentVolumeClaim:
      claimName: shared-logs

---
# Pod 3: Reader of shared logs
apiVersion: v1
kind: Pod
metadata:
  name: aggregator-pod
spec:
  containers:
  - name: reader
    image: busybox
    command: ["/bin/sh", "-c"]
    args:
      - |
        echo "Waiting for writers..."
        sleep 3
        echo "=== Shared Log ==="
        cat /logs/shared.log
        echo "=== App1 Log ==="
        cat /logs/app1.log
        echo "=== App2 Log ==="
        cat /logs/app2.log
        sleep 3600
    volumeMounts:
    - mountPath: /logs
      name: shared-logs
  volumes:
  - name: shared-logs
    persistentVolumeClaim:
      claimName: shared-logs
```

### Commands
```bash
# Create all Pods
kubectl apply -f multi-writer.yaml

# Wait for pods to complete writing
sleep 10

# Check aggregator's view of shared logs
kubectl logs aggregator-pod

# All logs should be visible:
# [App1-app-pod-1] Entry 1: ...
# [App2-app-pod-2] Entry 1: ...
# [App1] Completed at ...
# [App2] Completed at ...

# This proves multiple Pods can write to same volume!
```

---

## Scenario 3: Shared Volume with Multiple StorageClasses

**Task**: Compare different StorageClass options for shared volumes.

### YAML with Multiple Options
```yaml
---
# Option 1: NFS StorageClass
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: nfs-shared
provisioner: nfs.csi.k8s.io
allowVolumeExpansion: true
parameters:
  nfsvers: "4.1"

---
# Option 2: Manual NFS PV (pre-created)
apiVersion: v1
kind: PersistentVolume
metadata:
  name: nfs-manual-pv
spec:
  capacity:
    storage: 50Gi
  accessModes:
    - ReadWriteMany
  nfs:
    server: 192.168.1.100      # NFS server IP
    path: /exports/kubernetes

---
# Option 3: GlusterFS (if available)
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: glusterfs-shared
provisioner: glusterfs.org/glusterblock
allowVolumeExpansion: true

---
# PVC using NFS StorageClass
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: pvc-nfs-shared
spec:
  accessModes:
    - ReadWriteMany
  resources:
    requests:
      storage: 10Gi
  storageClassName: nfs-shared

---
# PVC using manual NFS PV
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: pvc-manual-nfs
spec:
  accessModes:
    - ReadWriteMany
  resources:
    requests:
      storage: 10Gi
  storageClassName: default  # No class for manual PV binding
```

### Commands to Compare
```bash
# List available StorageClasses that support RWX
kubectl get sc -o json | jq '.items[] | select(.provisioner | contains("nfs") or contains("gluster")) | {name:.metadata.name, provisioner:.provisioner}'

# Create PVCs with different providers
kubectl apply -f multi-storage-classes.yaml

# Check which one bound first (dynamic provisioning)
kubectl get pvc

# For manual NFS PV, verify mount details
kubectl describe pv nfs-manual-pv

# Create test Pods with each PVC
# Then verify all support RWX properly
```

---

## Scenario 4: Shared Volume for Configuration Distribution

**Task**: Use shared volume to distribute configuration to multiple Pods.

### Scenario: Central Config Manager
```yaml
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: config-share
spec:
  accessModes:
    - ReadWriteMany
  resources:
    requests:
      storage: 1Gi
  storageClassName: nfs

---
# Config Manager Pod (runs once to set up config)
apiVersion: v1
kind: Pod
metadata:
  name: config-manager
spec:
  containers:
  - name: setup
    image: busybox
    command: ["/bin/sh", "-c"]
    args:
      - |
        mkdir -p /config/myapp
        
        # Write configuration
        cat > /config/myapp/config.yaml << 'EOF'
        app_name: myapp
        version: 1.0
        debug: false
        log_level: info
        max_workers: 10
        EOF
        
        cat > /config/myapp/database.conf << 'EOF'
        DB_HOST: postgres.default.svc.cluster.local
        DB_PORT: 5432
        DB_NAME: myapp_db
        EOF
        
        echo "Config setup complete at $(date)"
        sleep 3600
    volumeMounts:
    - mountPath: /config
      name: config-share
  volumes:
  - name: config-share
    persistentVolumeClaim:
      claimName: config-share

---
# App Pod 1: Reads config
apiVersion: v1
kind: Pod
metadata:
  name: app1
spec:
  containers:
  - name: app
    image: busybox
    command: ["/bin/sh", "-c"]
    args:
      - |
        echo "Starting App1..."
        sleep 1
        
        echo "=== Loading config ==="
        cat /etc/myapp/config.yaml
        
        echo "=== Loading db config ==="
        cat /etc/myapp/database.conf
        
        echo "App1 running with config..."
        sleep 3600
    volumeMounts:
    - mountPath: /etc/myapp
      name: config-share
      subPath: myapp        # Read from myapp subdirectory
  volumes:
  - name: config-share
    persistentVolumeClaim:
      claimName: config-share

---
# App Pod 2: Also reads same config
apiVersion: v1
kind: Pod
metadata:
  name: app2
spec:
  containers:
  - name: app
    image: busybox
    command: ["/bin/sh", "-c"]
    args:
      - |
        echo "Starting App2..."
        sleep 1
        
        echo "=== Loading config ==="
        cat /etc/myapp/config.yaml
        
        echo "=== Loading db config ==="
        cat /etc/myapp/database.conf
        
        echo "App2 running with config..."
        sleep 3600
    volumeMounts:
    - mountPath: /etc/myapp
      name: config-share
      subPath: myapp        # Read from same directory
  volumes:
  - name: config-share
    persistentVolumeClaim:
      claimName: config-share
```

### Commands
```bash
# Create config and app Pods
kubectl apply -f config-distribution.yaml

# Wait for config manager to complete
sleep 2

# Verify both apps loaded same config
kubectl logs app1 | grep -A 3 "Loading config"
kubectl logs app2 | grep -A 3 "Loading config"

# Both should output identical configuration

# Update configuration in manager
kubectl exec config-manager -- sh -c 'echo "log_level: debug" >> /config/myapp/config.yaml'

# Apps can immediately see updated config (if they re-read)
kubectl exec app1 -- cat /etc/myapp/config.yaml | grep log_level
kubectl exec app2 -- cat /etc/myapp/config.yaml | grep log_level
```

---

## Scenario 5: Shared Volume Performance Considerations

**Task**: Understand and monitor shared volume performance.

### YAML
```yaml
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: perf-test
spec:
  accessModes:
    - ReadWriteMany
  resources:
    requests:
      storage: 50Gi
  storageClassName: nfs

---
# Multiple heavy I/O writers
apiVersion: v1
kind: Pod
metadata:
  name: heavy-writer
spec:
  containers:
  - name: writer
    image: busybox
    command: ["/bin/sh", "-c"]
    args:
      - |
        echo "Starting heavy I/O..."
        
        # Generate 1GB of data
        dd if=/dev/zero of=/data/large-file.bin bs=1M count=1024 oflag=direct 2>&1 | tee /data/write.log
        
        echo "Write complete at $(date)" >> /data/write.log
        sleep 3600
    volumeMounts:
    - mountPath: /data
      name: shared
  volumes:
  - name: shared
    persistentVolumeClaim:
      claimName: perf-test
```

### Performance Monitoring Commands
```bash
# Create heavy workload
kubectl apply -f perf-test.yaml

# Monitor from Pod
kubectl exec heavy-writer -- sh -c 'while true; do echo "=== $(date) ==="; du -sh /data; sleep 5; done'

# Monitor write progress
kubectl exec heavy-writer -- tail -f /data/write.log

# Monitor network (if NFS over network)
# From node: iftop or nethogs to see network usage

# Monitor iops
kubectl exec heavy-writer -- iostat -x 1

# Test read performance
kubectl exec heavy-writer -- dd if=/data/large-file.bin of=/dev/null bs=1M count=1024 2>&1
```

### Performance Optimization Tips
```bash
# 1. Tune NFS mount options (admin-level)
# 2. Use read-heavy workloads (NFS caching)
# 3. Consider local storage for non-shared data
# 4. Monitor latency and bandwidth
# 5. Adjust provisioner IOPS/throughput settings

# Check PVC provisioning details
kubectl get pvc perf-test -o yaml | grep -A 10 parameters
```

---

## Scenario 6: Troubleshooting Shared Volumes

### Issue 1: "Multi-Attach Error: Volume is already exclusively attached"

```bash
# Error: PVC created with RWO instead of RWX

# Check access mode
kubectl get pvc my-pvc -o jsonpath='{.spec.accessModes}'

# If shows [ReadWriteOnce] but need RWX:
# 1. Delete PVC (and associated PVs)
kubectl delete pvc my-pvc

# 2. Create new PVC with RWX
kubectl apply -f pvc-rwx.yaml

# Note: Cannot change access mode of existing PVC
```

### Issue 2: "Provisioner does not support RWX"

```bash
# Check provisioner capabilities
kubectl get sc <name> -o yaml

# Some provisioners don't support RWX:
# - kubernetes.io/host-path (local only)
# - kubernetes.io/no-provisioner (static only)
# - Some cloud providers

# Solution: Use different StorageClass
# kubectl patch pvc my-pvc -p '{"spec":{"storageClassName":"nfs-shared"}}'
```

### Issue 3: "NFS Mount Failed"

```bash
# Check NFS server connectivity (from Pod)
kubectl exec <pod> -- nslookup nfs.example.com

# Test NFS mount (manually on node)
# From node:
mount -t nfs 192.168.1.100:/exports/data /mnt/test

# Check NFS server exports
# On NFS server:
showmount -e

# Check firewall (port 2049 for NFS)
```

### Issue 4: "File Locking Issues with RWX"

```bash
# Problem: Multiple Pods writing to same file simultaneously

# Solution 1: Use file-level locking (flock, fcntl)
# Solution 2: Use separate files per Pod
# Solution 3: Use distributed database instead of files

# Example with separate files:
# Pod1 writes to /data/pod1.log
# Pod2 writes to /data/pod2.log
# Both Pods read from both files
```

---

## CKA Exam Tips

- **RWX requires special provisioner**: Not all StorageClasses support it
- **NFS is most common**: Know basic NFS PVC usage
- **Multiple Pods access**: Verify all Pods can read/write
- **Performance awareness**: Know RWX may have latency vs local storage
- **Troubleshooting**: Check access mode, provisioner support, network connectivity
- **Use cases**: Config distribution, log aggregation, shared data
- **Limitations**: File locking, consistency, performance compared to RWO

---

## Quick Reference

| Task | Command |
|------|---------|
| Check access mode | `kubectl get pvc <name> -o jsonpath='{.spec.accessModes}'` |
| Verify RWX support | `kubectl describe sc <name> \| grep provisioner` |
| Create RWX PVC | Ensure `accessModes: [ReadWriteMany]` in YAML |
| Test multiple Pods | Create 2+ Pods with same PVC, verify all write/read |
| Check NFS mount | `kubectl exec <pod> -- df -h` |
| Monitor usage | `kubectl exec <pod> -- du -sh /path` |
| Fix RWO to RWX | Delete PVC, recreate with `ReadWriteMany` |

---

## See Also
- `scenarios-pvc.md` — PVC creation and access modes
- `scenarios-pvc-pod.md` — Pod and PVC integration
- `scenarios/shared-volume/` — Scenario walkthroughs
