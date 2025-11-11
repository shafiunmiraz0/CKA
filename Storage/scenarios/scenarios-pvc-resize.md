# PersistentVolumeClaim Resize — Scenarios & Commands

## Overview
**PVC Resize** allows you to increase the storage capacity of a PersistentVolumeClaim after initial creation. This is useful when applications need more space without recreating volumes.

---

## Scenario 1: Basic PVC Resize

**Task**: Increase PVC size from initial capacity.

### Prerequisites
```bash
# StorageClass must allow expansion
kubectl describe sc standard | grep -i "allow"

# Should show: AllowVolumeExpansion: true
```

### YAML Setup
```yaml
---
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: expandable
provisioner: ebs.csi.aws.com  # Or your CSI provisioner
allowVolumeExpansion: true    # MUST be true for resize
reclaimPolicy: Delete

---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: data-pvc
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 5Gi            # Initial size
  storageClassName: expandable

---
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
        dd if=/dev/zero of=/data/largefile.bin bs=1M count=4096  # 4GB file
        sleep 3600
    volumeMounts:
    - mountPath: /data
      name: storage
  volumes:
  - name: storage
    persistentVolumeClaim:
      claimName: data-pvc
```

### Commands to Resize
```bash
# Create StorageClass, PVC, and Pod
kubectl apply -f setup.yaml

# Wait for Pod to fill up space (or get close)
sleep 10

# Check current PVC size
kubectl get pvc data-pvc

# Option 1: Resize using patch command
kubectl patch pvc data-pvc -p '{"spec":{"resources":{"requests":{"storage":"10Gi"}}}}'

# Option 2: Resize using edit
kubectl edit pvc data-pvc
# Find: spec.resources.requests.storage: 5Gi
# Change to: spec.resources.requests.storage: 10Gi
# Save and exit

# Option 3: Apply updated YAML
# Modify pvc.yaml locally with new size, then:
kubectl apply -f pvc.yaml

# Check resize status
kubectl describe pvc data-pvc

# Look for Conditions section:
# - Type: FileSystemResizePending
#   Status: true (resize in progress)

# Wait for resize to complete
kubectl get pvc data-pvc --watch

# Once FileSystemResizePending becomes false, resize complete
# Check new size inside Pod
kubectl exec app-pod -- df -h /data
```

### Expected Output
```bash
# After patch, PVC shows larger request
kubectl get pvc data-pvc
# NAME       STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS   AGE
# data-pvc   Bound    pvc-abc123def456xyz789                     10Gi       RWO            expandable     5m

# Pod filesystem auto-expanded
kubectl exec app-pod -- df -h /data
# Filesystem                Size      Used Available Use% Mounted on
# /dev/xvda                10G       4.0G  6.0G      40%  /data
```

---

## Scenario 2: Resize with Pending Status

**Task**: Understand and resolve PVC resize pending states.

### YAML
```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: resize-test-pvc
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 5Gi
  storageClassName: expandable

---
apiVersion: v1
kind: Pod
metadata:
  name: resize-test-pod
spec:
  containers:
  - name: app
    image: busybox
    command: ["sleep", "3600"]
    volumeMounts:
    - mountPath: /data
      name: storage
  volumes:
  - name: storage
    persistentVolumeClaim:
      claimName: resize-test-pvc
```

### Monitoring Resize Process
```bash
# Create setup
kubectl apply -f resize-test.yaml

# Resize PVC
kubectl patch pvc resize-test-pvc -p '{"spec":{"resources":{"requests":{"storage":"10Gi"}}}}'

# Immediately check status
kubectl describe pvc resize-test-pvc

# Look for Conditions:
# Type: Resizing
# Status: true

# Or:
# Type: FileSystemResizePending
# Status: true

# Monitor changes
kubectl describe pvc resize-test-pvc --watch

# Or use get with watch
kubectl get pvc resize-test-pvc -o custom-columns=NAME:.metadata.name,SIZE:.spec.resources.requests.storage,RESIZING:.status.conditions[?(@.type=="Resizing")].status,FS-PENDING:.status.conditions[?(@.type=="FileSystemResizePending")].status --watch

# Check Pod volume size
kubectl exec resize-test-pod -- df -h /data

# If filesystem size lags behind PVC request:
# - It's expanding asynchronously
# - Wait a few seconds and recheck

# If it's stuck, restart the Pod to trigger filesystem expansion
kubectl delete pod resize-test-pod
kubectl apply -f resize-test.yaml
```

### Conditions Explained
```
Resizing: true → PV storage is expanding (underlying cloud resource)
Resizing: false → PV expansion complete

FileSystemResizePending: true → Filesystem hasn't expanded yet
FileSystemResizePending: false → Filesystem fully expanded
```

---

## Scenario 3: Resizing During High Load

**Task**: Resize PVC while application is actively writing data.

### YAML
```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: busy-pvc
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 5Gi
  storageClassName: expandable

---
apiVersion: v1
kind: Pod
metadata:
  name: busy-app
spec:
  containers:
  - name: writer
    image: busybox
    command: ["/bin/sh", "-c"]
    args:
      - |
        i=0
        while true; do
          echo "Entry $i: $(date)" >> /data/output.log
          ((i++))
          sleep 1
        done
    volumeMounts:
    - mountPath: /data
      name: storage
  volumes:
  - name: storage
    persistentVolumeClaim:
      claimName: busy-pvc
```

### Commands
```bash
# Create busy application
kubectl apply -f busy-app.yaml

# Wait a bit for data to accumulate
sleep 10

# Check current usage
kubectl exec busy-app -- du -sh /data

# Resize while Pod is running
kubectl patch pvc busy-pvc -p '{"spec":{"resources":{"requests":{"storage":"20Gi"}}}}'

# Monitor resize
kubectl describe pvc busy-pvc

# Pod continues writing during resize (no downtime!)
kubectl exec busy-app -- wc -l /data/output.log

# Wait for resize to complete
sleep 5

# Check final size
kubectl exec busy-app -- df -h /data

# Pod continues uninterrupted - data written throughout resize
```

### Key Advantage
- **No downtime**: Pod keeps running during resize
- **Non-blocking**: App can continue writing/reading
- **Async expansion**: Resize happens in background

---

## Scenario 4: Troubleshooting Resize Failures

### Issue 1: "Cannot resize to smaller size"
```bash
# Error: "new size must be greater than current size"

# Cause: Attempted to decrease PVC size (not allowed)

# Current size
kubectl get pvc my-pvc -o jsonpath='{.spec.resources.requests.storage}'

# Attempted resize to smaller value
# kubectl patch pvc my-pvc -p '{"spec":{"resources":{"requests":{"storage":"3Gi"}}}}'  # ❌ WRONG

# Fix: Request larger size instead
kubectl patch pvc my-pvc -p '{"spec":{"resources":{"requests":{"storage":"10Gi"}}}}'  # ✓ Correct
```

### Issue 2: "Provisioner does not support expansion"
```bash
# Error: "provisioner does not support resize"

# Check if StorageClass allows expansion
kubectl describe sc <name> | grep -i "allow"

# If AllowVolumeExpansion is false:
# Either:
# 1. Use different StorageClass that supports expansion
#    kubectl patch pvc my-pvc -p '{"spec":{"storageClassName":"expandable"}}'
# 2. Or ensure current provisioner supports it

# Some provisioners that DON'T support expansion:
# - kubernetes.io/no-provisioner
# - kubernetes.io/host-path (locally)
# - Some legacy provisioners
```

### Issue 3: "FileSystemResizePending stuck at true"
```bash
# Filesystem didn't auto-expand after PV expansion

# Possible causes:
# - Filesystem type doesn't auto-expand (e.g., XFS)
# - Pod not restarted
# - Device not fully expanded yet

# Solutions:
# 1. Restart Pod to trigger filesystem resize
kubectl delete pod <pod-using-pvc>
kubectl apply -f pod.yaml

# 2. Or manually resize filesystem inside Pod (if needed)
kubectl exec <pod> -- sh -c 'resize2fs /dev/xvda'  # For ext4

# 3. Check filesystem type
kubectl exec <pod> -- df -T /data

# 4. Check device size matches PVC request
kubectl exec <pod> -- lsblk
```

### Issue 4: "FileSystemResizePending stuck while Pod evicted"
```bash
# Pod evicted, filesystem resize incomplete

# Check Pod status
kubectl describe pod <pod-name>

# If Evicted: recreate Pod
kubectl delete pod <pod-name>

# Apply Pod YAML to recreate with same PVC reference
kubectl apply -f pod.yaml

# Filesystem resize should complete on new Pod startup
```

---

## Scenario 5: Resize Monitoring and Alerts

**Task**: Monitor PVC size and set up preemptive resizing.

### Commands to Monitor
```bash
# Watch PVC usage in real-time
kubectl get pvc --watch

# Get PVC size details
kubectl get pvc my-pvc -o json | jq '.spec.resources.requests'

# Check Pod's actual disk usage
kubectl exec <pod-using-pvc> -- df -h

# Create alert trigger (manual check example)
CURRENT=$(kubectl get pvc my-pvc -o jsonpath='{.spec.resources.requests.storage}' | sed 's/Gi//')
USAGE=$(kubectl exec <pod-using-pvc> -- df /data | tail -1 | awk '{print $5}' | sed 's/%//')

echo "Current PVC: ${CURRENT}Gi"
echo "Current Usage: ${USAGE}%"

if [ $USAGE -gt 80 ]; then
  echo "Usage above 80%, resizing..."
  NEW_SIZE=$((CURRENT + 10))
  kubectl patch pvc my-pvc -p "{\"spec\":{\"resources\":{\"requests\":{\"storage\":\"${NEW_SIZE}Gi\"}}}}"
fi
```

### Automated Monitoring Script
```bash
#!/bin/bash
# auto-resize.sh - Auto-resize PVC when usage exceeds threshold

PVC_NAME="my-pvc"
THRESHOLD=80  # Resize when usage > 80%
NAMESPACE="default"

while true; do
  # Get Pod using this PVC
  POD=$(kubectl get pods -n $NAMESPACE -o json | \
    jq -r ".items[] | select(.spec.volumes[]?.persistentVolumeClaim.claimName==\"$PVC_NAME\") | .metadata.name" | head -1)
  
  if [ -z "$POD" ]; then
    echo "No Pod found using PVC $PVC_NAME"
    sleep 300
    continue
  fi
  
  # Get current PVC size
  CURRENT=$(kubectl get pvc $PVC_NAME -n $NAMESPACE -o jsonpath='{.spec.resources.requests.storage}' | sed 's/Gi//')
  
  # Get Pod disk usage
  USAGE=$(kubectl exec -n $NAMESPACE $POD -- df /data 2>/dev/null | tail -1 | awk '{print $5}' | sed 's/%//')
  
  echo "[$(date)] PVC: ${CURRENT}Gi, Usage: ${USAGE}%"
  
  if [ "$USAGE" -gt "$THRESHOLD" ]; then
    echo "Usage above ${THRESHOLD}%, resizing..."
    NEW_SIZE=$((CURRENT + 10))
    kubectl patch pvc $PVC_NAME -n $NAMESPACE -p "{\"spec\":{\"resources\":{\"requests\":{\"storage\":\"${NEW_SIZE}Gi\"}}}}"
    echo "Resized to ${NEW_SIZE}Gi"
  fi
  
  sleep 300  # Check every 5 minutes
done
```

---

## Scenario 6: Resize Across Multiple PVCs

**Task**: Resize multiple PVCs at once (e.g., app has multiple volumes).

### YAML
```yaml
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: data-pvc
  labels:
    app: myapp
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 5Gi
  storageClassName: expandable

---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: logs-pvc
  labels:
    app: myapp
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 10Gi
  storageClassName: expandable

---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: cache-pvc
  labels:
    app: myapp
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 2Gi
  storageClassName: expandable
```

### Commands to Resize All
```bash
# Create all PVCs
kubectl apply -f multi-pvc.yaml

# List all app PVCs
kubectl get pvc -l app=myapp

# Resize single PVC
kubectl patch pvc data-pvc -p '{"spec":{"resources":{"requests":{"storage":"10Gi"}}}}'

# Resize all PVCs with label app=myapp
for pvc in $(kubectl get pvc -l app=myapp -o jsonpath='{.items[*].metadata.name}'); do
  echo "Resizing $pvc..."
  kubectl patch pvc $pvc -p '{"spec":{"resources":{"requests":{"storage":"20Gi"}}}}'
done

# Verify all resized
kubectl get pvc -l app=myapp

# Monitor all resizes
kubectl get pvc -l app=myapp --watch
```

---

## CKA Exam Tips

- **Prerequisites**: StorageClass must have `allowVolumeExpansion: true`
- **Only increase**: Can only resize up, never down
- **No downtime**: Pod keeps running during resize
- **Monitor conditions**: Know `Resizing` and `FileSystemResizePending` states
- **Pod restart may help**: If filesystem resize stuck, restart Pod
- **Patch command**: Fastest way is `kubectl patch pvc <name> -p '...'`
- **Verify success**: Check Pod's `df -h` to confirm filesystem expanded
- **Not all provisioners support**: Know which cloud providers/provisioners allow expansion

---

## Quick Reference

| Task | Command |
|------|---------|
| Check if expandable | `kubectl describe sc <name> \| grep -i allow` |
| Resize PVC | `kubectl patch pvc <name> -p '{"spec":{"resources":{"requests":{"storage":"10Gi"}}}}'` |
| Check resize status | `kubectl describe pvc <name>` |
| Watch resize | `kubectl get pvc <name> --watch` |
| Check Pod filesystem | `kubectl exec <pod> -- df -h` |
| Get current size | `kubectl get pvc <name> -o jsonpath='{.spec.resources.requests.storage}'` |
| Restart Pod | `kubectl delete pod <name> --grace-period=0 --force` |

---

## See Also
- `scenarios-pvc.md` — PVC creation and management
- `scenarios-pvc-pod.md` — Pod and PVC integration
- `scenarios/pvc-resize/` — Scenario walkthroughs
