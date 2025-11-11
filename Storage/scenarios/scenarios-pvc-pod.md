# PersistentVolumeClaim + Pod — Integration Scenarios

## Overview
This document covers the **Pod integration workflow**: creating a PersistentVolumeClaim, mounting it in a Pod, and verifying data persistence across Pod restarts.

---

## Scenario 1: Basic Pod with PVC Mount

**Task**: Create a PVC and mount it in a Pod for data persistence.

### Step 1: Create PersistentVolumeClaim
```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: app-data
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 2Gi
  storageClassName: standard
```

### Step 2: Create Pod with PVC Volume
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: app-pod
spec:
  containers:
  - name: app
    image: busybox
    command: ["/bin/sh", "-c"]
    args:
      - |
        echo "App is running"
        echo "Data created at $(date)" > /data/app.log
        sleep 3600
    volumeMounts:
    - mountPath: /data
      name: app-storage
  volumes:
  - name: app-storage
    persistentVolumeClaim:
      claimName: app-data  # Reference PVC by name
```

### Step 3: Apply and Verify
```bash
# Create PVC
kubectl apply -f pvc.yaml

# Verify PVC is Bound
kubectl get pvc app-data

# Create Pod
kubectl apply -f pod.yaml

# Verify Pod is Running
kubectl get pod app-pod

# Check Pod details
kubectl describe pod app-pod

# Verify volume mounted inside Pod
kubectl exec app-pod -- ls -la /data
kubectl exec app-pod -- cat /data/app.log
```

### Expected Output
```bash
# kubectl get pvc
NAME       STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS   AGE
app-data   Bound    pvc-abc123def456xyz789                     2Gi        RWO            standard       3m

# kubectl get pod
NAME      READY   STATUS    RESTARTS   AGE
app-pod   1/1     Running   0          1m

# kubectl exec app-pod -- ls /data
app.log
```

---

## Scenario 2: Data Persistence After Pod Restart

**Task**: Verify that data persists when a Pod is restarted.

### YAML Setup
```yaml
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: persistent-data
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 1Gi
  storageClassName: standard

---
apiVersion: v1
kind: Pod
metadata:
  name: persistent-app
spec:
  containers:
  - name: app
    image: busybox
    command: ["/bin/sh", "-c"]
    args:
      - |
        # Append to file instead of overwriting
        echo "Pod started at $(date)" >> /data/history.log
        sleep 3600
    volumeMounts:
    - mountPath: /data
      name: storage
  volumes:
  - name: storage
    persistentVolumeClaim:
      claimName: persistent-data
```

### Commands to Test Persistence
```bash
# Create PVC and Pod
kubectl apply -f persistent-app.yaml

# Wait for Pod to start
kubectl get pod persistent-app

# Check initial log
kubectl exec persistent-app -- cat /data/history.log

# Delete Pod (data should remain in PVC)
kubectl delete pod persistent-app

# PVC should still exist and contain data
kubectl get pvc persistent-data

# Recreate Pod with same PVC reference
kubectl apply -f persistent-app.yaml

# Wait for new Pod to start
sleep 5
kubectl get pod persistent-app

# Verify data persisted and new entry was added
kubectl exec persistent-app -- cat /data/history.log

# Output should show TWO timestamps:
# Pod started at Mon Dec 5 10:00:00 UTC 2024
# Pod started at Mon Dec 5 10:00:15 UTC 2024
```

### Verification Checklist
- [ ] Initial Pod writes data to /data
- [ ] PVC remains Bound after Pod deletion
- [ ] New Pod can access the existing data
- [ ] New Pod can append new data to the file

---

## Scenario 3: Multiple Containers in One Pod Using Same PVC

**Task**: Have multiple containers in a Pod share the same PVC volume.

### YAML
```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: shared-pvc
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 2Gi
  storageClassName: standard

---
apiVersion: v1
kind: Pod
metadata:
  name: multi-container-app
spec:
  containers:
  # Container 1: Writer
  - name: writer
    image: busybox
    command: ["/bin/sh", "-c"]
    args:
      - |
        while true; do
          echo "Data from writer at $(date)" >> /data/shared.txt
          sleep 5
        done
    volumeMounts:
    - mountPath: /data
      name: storage
  
  # Container 2: Reader
  - name: reader
    image: busybox
    command: ["/bin/sh", "-c"]
    args:
      - |
        sleep 2  # Let writer start first
        while true; do
          echo "=== Reader sees ==="
          cat /data/shared.txt
          sleep 10
        done
    volumeMounts:
    - mountPath: /data
      name: storage
  
  volumes:
  - name: storage
    persistentVolumeClaim:
      claimName: shared-pvc
```

### Commands
```bash
# Create PVC and Pod with multiple containers
kubectl apply -f multi-container-app.yaml

# Verify both containers are running
kubectl get pod multi-container-app

# Check logs from writer container
kubectl logs multi-container-app -c writer

# Check logs from reader container
kubectl logs multi-container-app -c reader

# Verify they see the same file
kubectl exec multi-container-app -c writer -- cat /data/shared.txt
kubectl exec multi-container-app -c reader -- cat /data/shared.txt
```

### Key Points
- Multiple containers in one Pod can mount the same PVC
- Access mode RWO allows multiple containers on SAME Pod
- Only one Pod (with multiple containers) can have exclusive access
- For multiple Pods to share, use RWX access mode

---

## Scenario 4: Pod with Initialization Data from PVC

**Task**: Use initContainer to initialize volume data before main application starts.

### YAML
```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: app-config-pvc
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 1Gi
  storageClassName: standard

---
apiVersion: v1
kind: Pod
metadata:
  name: app-with-init
spec:
  # Init container runs first to set up volume
  initContainers:
  - name: setup
    image: busybox
    command: ["sh", "-c"]
    args:
      - |
        echo "Initializing data..."
        mkdir -p /data/config
        cat > /data/config/settings.txt << 'EOF'
        APP_MODE=production
        LOG_LEVEL=info
        MAX_CONNECTIONS=100
        EOF
        echo "Initialization complete"
    volumeMounts:
    - mountPath: /data
      name: storage

  # Main container uses initialized data
  containers:
  - name: app
    image: busybox
    command: ["/bin/sh", "-c"]
    args:
      - |
        echo "Starting application..."
        cat /data/config/settings.txt
        echo "App running..."
        sleep 3600
    volumeMounts:
    - mountPath: /data
      name: storage

  volumes:
  - name: storage
    persistentVolumeClaim:
      claimName: app-config-pvc
```

### Commands
```bash
# Create PVC and Pod
kubectl apply -f app-with-init.yaml

# Monitor Pod creation
kubectl get pod app-with-init --watch

# initContainer runs first; Pod shows Init:0/1
# After init complete, main container starts

# Check logs from init container
kubectl logs app-with-init -c setup

# Check logs from main container
kubectl logs app-with-init -c app

# Verify initialized data
kubectl exec app-with-init -- cat /data/config/settings.txt

# Verify data persists on PVC
kubectl exec -it app-with-init -- ls -la /data/config/
```

---

## Scenario 5: Debugging Pod-PVC Issues

**Task**: Diagnose and resolve Pod and PVC mounting problems.

### Issue 1: PVC Pending, Pod Won't Start

```bash
# Check Pod status
kubectl get pod app-pod

# If status is Pending, check Pod events
kubectl describe pod app-pod

# Look for: "waiting for PersistentVolumeClaim"

# Check if PVC exists and is Bound
kubectl get pvc app-data

# If PVC is Pending, fix the PVC first
# (See scenarios-pvc.md for PVC troubleshooting)

# Once PVC is Bound, Pod should start
kubectl get pod app-pod
```

### Issue 2: Volume Mount Permission Denied

```bash
# Error: "permission denied" when writing to mounted volume

# Check Pod logs
kubectl logs app-pod

# SSH into Pod and check permissions
kubectl exec -it app-pod -- sh

# Inside Pod:
ls -la /data            # Check mount permissions
whoami                  # Check running user
id                      # Check UID/GID

# Issue often occurs when:
# - Container runs as non-root but volume owned by root
# - SELinux/AppArmor restrictions

# Solution: Run container as root or set fsGroup
```

### Issue 3: Pod Evicted Due to StorageClass

```bash
# Pod shows Evicted status
kubectl get pod app-pod

# Check Pod status details
kubectl describe pod app-pod

# Look for: "Evicted" with reason "Storage.*" 

# Possible causes:
# - StorageClass provisioner not available
# - Storage backend unavailable
# - Storage quota exceeded

# Solution: Check provisioner status
kubectl get pods -n kube-system | grep csi

# Check provisioner logs
kubectl logs -n kube-system <provisioner-pod>
```

### Issue 4: Can't Verify Volume Mount

```bash
# Try to check if volume is mounted
kubectl exec pod-name -- df -h

# If mount not visible, check Pod spec
kubectl get pod app-pod -o yaml | grep -A 5 volumeMounts

# Verify PVC name is correct
kubectl get pvc

# Verify mountPath exists in container
# (volume auto-creates mountPath if missing)
```

---

## Scenario 6: Writing and Reading from Mounted Volume

**Task**: Test read/write operations on mounted PVC volume.

### YAML
```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: data-store
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 1Gi
  storageClassName: standard

---
apiVersion: v1
kind: Pod
metadata:
  name: data-writer
spec:
  containers:
  - name: app
    image: busybox
    command: ["/bin/sh", "-c"]
    args:
      - |
        echo "Starting data writer..."
        
        # Create directory
        mkdir -p /mnt/storage/logs
        
        # Write multiple files
        for i in {1..10}; do
          echo "Entry $i at $(date)" >> /mnt/storage/logs/data.txt
          sleep 1
        done
        
        echo "Data written. Keeping Pod alive..."
        sleep 3600
    
    volumeMounts:
    - mountPath: /mnt/storage
      name: app-storage
  
  volumes:
  - name: app-storage
    persistentVolumeClaim:
      claimName: data-store
```

### Commands to Test Read/Write
```bash
# Create PVC and Pod
kubectl apply -f data-writer.yaml

# Wait for Pod to complete writing
sleep 15

# Read from mounted volume
kubectl exec data-writer -- cat /mnt/storage/logs/data.txt

# Expected output: 10 entries with timestamps

# List files in volume
kubectl exec data-writer -- find /mnt/storage -type f

# Check volume usage
kubectl exec data-writer -- df -h /mnt/storage

# Append more data while Pod is running
kubectl exec data-writer -- echo "New line: $(date)" >> /mnt/storage/logs/data.txt

# Verify new data was written
kubectl exec data-writer -- tail -1 /mnt/storage/logs/data.txt

# Check file size growth
kubectl exec data-writer -- du -sh /mnt/storage
```

---

## Scenario 7: Pod with ReadOnlyMany Access

**Task**: Create multiple Pods that read from the same RWX PVC volume.

### YAML
```yaml
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: shared-data
spec:
  accessModes:
    - ReadWriteMany  # Multiple Pods can access
  resources:
    requests:
      storage: 5Gi
  storageClassName: nfs  # Requires NFS or CSI with RWX support

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
          echo "Writer: $(date)" >> /data/shared.txt
          sleep 2
        done
    volumeMounts:
    - mountPath: /data
      name: shared
  volumes:
  - name: shared
    persistentVolumeClaim:
      claimName: shared-data

---
# Pod 2: Reader
apiVersion: v1
kind: Pod
metadata:
  name: reader-pod-1
spec:
  containers:
  - name: reader
    image: busybox
    command: ["/bin/sh", "-c"]
    args:
      - |
        sleep 1
        while true; do
          echo "--- Reader sees ---"
          cat /data/shared.txt
          echo "--- End ---"
          sleep 5
        done
    volumeMounts:
    - mountPath: /data
      name: shared
  volumes:
  - name: shared
    persistentVolumeClaim:
      claimName: shared-data

---
# Pod 3: Another Reader
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
        sleep 1
        cat /data/shared.txt
        echo "Reader 2: All data read successfully"
        sleep 3600
    volumeMounts:
    - mountPath: /data
      name: shared
  volumes:
  - name: shared
    persistentVolumeClaim:
      claimName: shared-data
```

### Commands
```bash
# Create PVC with RWX access mode
kubectl apply -f shared-volume.yaml

# Create all Pods
kubectl apply -f writer-pod.yaml
kubectl apply -f reader-pod-1.yaml
kubectl apply -f reader-pod-2.yaml

# Verify all Pods are running
kubectl get pods

# Check writer logs
kubectl logs writer-pod | head -10

# Check reader logs
kubectl logs reader-pod-1 | head -10
kubectl logs reader-pod-2

# Both readers should see data written by writer
# Even though PVC is mounted in multiple Pods!
```

---

## Scenario 8: Using Subpaths

**Task**: Use multiple volumes from single PVC with subpath.

### YAML
```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: multi-app-storage
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 10Gi
  storageClassName: standard

---
apiVersion: v1
kind: Pod
metadata:
  name: multi-app-pod
spec:
  containers:
  # App 1: Uses /data/app1
  - name: app1
    image: busybox
    command: ["/bin/sh", "-c"]
    args:
      - |
        echo "App1 starting"
        echo "App1: $(date)" > /app1/data.txt
        sleep 3600
    volumeMounts:
    - mountPath: /app1
      name: storage
      subPath: app1-data      # Isolated within PVC
  
  # App 2: Uses /data/app2
  - name: app2
    image: busybox
    command: ["/bin/sh", "-c"]
    args:
      - |
        echo "App2 starting"
        echo "App2: $(date)" > /app2/data.txt
        sleep 3600
    volumeMounts:
    - mountPath: /app2
      name: storage
      subPath: app2-data      # Isolated within PVC
  
  # App 3: Uses /logs
  - name: app3
    image: busybox
    command: ["/bin/sh", "-c"]
    args:
      - |
        echo "App3 starting"
        echo "App3: $(date)" > /logs/app3.log
        sleep 3600
    volumeMounts:
    - mountPath: /logs
      name: storage
      subPath: logs           # Isolated within PVC
  
  volumes:
  - name: storage
    persistentVolumeClaim:
      claimName: multi-app-storage
```

### Commands
```bash
# Create PVC and Pod with subpaths
kubectl apply -f multi-app-pod.yaml

# Verify all containers running
kubectl get pod multi-app-pod

# Check each container's isolated data
kubectl exec multi-app-pod -c app1 -- cat /app1/data.txt
kubectl exec multi-app-pod -c app2 -- cat /app2/data.txt
kubectl exec multi-app-pod -c app3 -- cat /logs/app3.log

# Verify isolation: try to access other app's data
kubectl exec multi-app-pod -c app1 -- ls -la /app1
kubectl exec multi-app-pod -c app1 -- ls -la /app2 2>&1  # Will show only app1 mount

# All data in same PVC but isolated by subPath
```

### Benefits of subPath
- Single PVC, multiple isolated mount points
- Different containers can access different parts
- Useful for shared storage between co-located containers
- Reduces number of PVCs needed

---

## CKA Exam Tips

- **Basic mounting**: Master `volumeMounts` + `volumes.persistentVolumeClaim` syntax
- **Persistence verification**: Know how to verify data survives Pod restart
- **RWO vs RWX**: RWO for single Pod, RWX for multiple Pods (if provisioner supports)
- **Init containers**: Know how to use initContainers for volume setup
- **Debugging**: Use `kubectl exec` to verify mounts from inside Pod
- **Permissions**: Understand fsGroup for permission issues
- **subPath**: Know subPath for isolating multiple apps in one PVC
- **Real-world workflow**: Create PVC → Create Pod with volumeMount → Verify → Test persistence

---

## Quick Reference

| Task | Command |
|------|---------|
| Create Pod with PVC | See YAML template above |
| Mount volume | `volumeMounts: [{mountPath: /data, name: storage}]` |
| Reference PVC | `volumes: [{name: storage, persistentVolumeClaim: {claimName: my-pvc}}]` |
| Check mount inside Pod | `kubectl exec pod -- df -h` |
| Read from volume | `kubectl exec pod -- cat /data/file.txt` |
| Write to volume | `kubectl exec pod -- sh -c 'echo data > /data/file'` |
| Use subPath | `subPath: subdir` in volumeMount |
| Verify persistence | Delete Pod, recreate, check data still exists |

---

## See Also
- `scenarios-pvc.md` — PVC creation and management
- `scenarios-pv.md` — PV creation and management
- `scenarios/pvc-pod/` — Scenario walkthroughs
