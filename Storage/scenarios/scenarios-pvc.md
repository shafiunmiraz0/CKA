# PersistentVolumeClaim (PVC) — Scenarios & Commands

## Overview
A **PersistentVolumeClaim (PVC)** is a request for storage by a Pod. PVCs consume PersistentVolumes and provide an abstraction layer between application requirements and storage implementation.

---

## Scenario 1: Create a Simple PVC

**Task**: Create a PersistentVolumeClaim with basic configuration.

### YAML
```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: my-pvc
  namespace: default
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 2Gi
  storageClassName: standard
```

### Commands
```bash
# Create PVC
kubectl apply -f pvc.yaml

# Verify PVC is created
kubectl get pvc
kubectl get pvc -A                    # List across all namespaces
kubectl describe pvc my-pvc
kubectl describe pvc my-pvc -n default

# Check PVC YAML
kubectl get pvc my-pvc -o yaml
kubectl get pvc my-pvc -o json
```

### Verification Checklist
- [ ] PVC status is `Bound` (if PV available) or `Pending` (if waiting for provisioning)
- [ ] Capacity shows requested storage (e.g., 2Gi)
- [ ] Volume name shows bound PV name (if Bound)

### Key Concepts
- **Access Modes**: `ReadWriteOnce` — single pod read/write
- **Storage Request**: `2Gi` — amount of storage needed
- **Storage Class**: `standard` — provisioner that will satisfy this claim

---

## Scenario 2: PVC with Dynamic Provisioning

**Task**: Create a PVC that triggers automatic PV creation via StorageClass.

### YAML
```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: dynamic-pvc
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 5Gi
  storageClassName: fast-ssd  # Must exist as StorageClass
```

### Commands
```bash
# First, verify StorageClass exists
kubectl get storageclass
kubectl describe storageclass fast-ssd

# Create PVC
kubectl apply -f pvc-dynamic.yaml

# Monitor PVC creation (watch for status transition)
kubectl get pvc dynamic-pvc --watch

# Once Bound, verify PV was auto-created
kubectl get pv

# Check provisioning status
kubectl describe pvc dynamic-pvc
kubectl get events --sort-by='.lastTimestamp'
```

### Expected Output
```
NAME           STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS   AGE
dynamic-pvc    Bound    pvc-abc123def456                           5Gi        RWO            fast-ssd       2m
```

### Key Points
- **Automatic PV creation**: StorageClass provisioner creates PV automatically
- **Binding**: PVC is Bound when PV is created and available
- **Events**: Check `kubectl describe pvc` for provisioning errors

---

## Scenario 3: Static Binding (PVC to Existing PV)

**Task**: Create a PVC that binds to a pre-existing PersistentVolume.

### Step 1: Create Static PV
```yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: static-pv
spec:
  capacity:
    storage: 5Gi
  accessModes:
    - ReadWriteOnce
  storageClassName: manual
  persistentVolumeReclaimPolicy: Retain
  hostPath:
    path: /mnt/data/static
```

### Step 2: Create PVC with Matching Spec
```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: static-pvc
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 5Gi  # Must be <= PV capacity
  storageClassName: manual  # Must match PV
```

### Commands
```bash
# Create PV first
kubectl apply -f pv-static.yaml

# Verify PV is Available
kubectl get pv static-pv

# Create PVC
kubectl apply -f pvc-static.yaml

# Verify binding
kubectl get pvc static-pvc
kubectl get pv static-pv

# Both should show Bound status
kubectl describe pvc static-pvc
kubectl describe pv static-pv
```

### Important Matching Rules
```
✓ PVC capacity request <= PV capacity
✓ PVC accessModes ⊆ PV accessModes (subset)
✓ PVC storageClassName = PV storageClassName
✓ PV must be Available (not already Bound)
```

---

## Scenario 4: Troubleshooting PVC in Pending State

**Task**: Diagnose and resolve PVC Pending status.

### Case 1: No StorageClass Available

```bash
# List all PVCs
kubectl get pvc

# Check PVC events for errors
kubectl describe pvc my-pvc

# Look for: "storageclass.storage.k8s.io "fast" not found"

# Solution: Check available StorageClasses
kubectl get storageclass

# Update PVC to use existing StorageClass
kubectl patch pvc my-pvc -p '{"spec":{"storageClassName":"standard"}}'
```

### Case 2: No Matching PV for Static Binding

```bash
# Check PVC spec
kubectl describe pvc my-pvc

# Look for: "no PV available for dynamic provisioning"

# Solution: Create matching PV
kubectl apply -f pv-matching.yaml

# Or use dynamic provisioning
kubectl patch pvc my-pvc -p '{"spec":{"storageClassName":"dynamic"}}'
```

### Case 3: Provisioner Not Ready

```bash
# Check provisioner availability
kubectl get pods -n kube-system | grep csi

# Check provisioner logs
kubectl logs -n kube-system <csi-provisioner-pod>

# Check PVC events
kubectl describe pvc my-pvc | tail -20

# Check cluster events
kubectl get events --sort-by='.lastTimestamp' | tail -10
```

### Debugging Commands
```bash
# Get detailed PVC info
kubectl get pvc my-pvc -o yaml

# Watch PVC status changes
kubectl get pvc my-pvc --watch

# Check all events in namespace
kubectl get events -n default --sort-by='.lastTimestamp'

# Check provisioner pod logs
kubectl logs -n kube-system deployment/csi-provisioner
```

---

## Scenario 5: PVC Access Modes

**Task**: Create PVCs with different access modes.

### YAML Examples

#### ReadWriteOnce (Single Pod)
```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: pvc-rwo
spec:
  accessModes:
    - ReadWriteOnce  # Only one pod can mount and write
  resources:
    requests:
      storage: 2Gi
  storageClassName: standard
```

#### ReadOnlyMany (Multiple Pods, Read-Only)
```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: pvc-rox
spec:
  accessModes:
    - ReadOnlyMany  # Multiple pods can mount, but read-only
  resources:
    requests:
      storage: 2Gi
  storageClassName: standard
```

#### ReadWriteMany (Multiple Pods, Read/Write)
```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: pvc-rwx
spec:
  accessModes:
    - ReadWriteMany  # Multiple pods can mount and write
  resources:
    requests:
      storage: 2Gi
  storageClassName: nfs  # Requires NFS or similar provisioner
```

### Access Mode Constraints
```
ReadWriteOnce (RWO):
  - Default choice for most workloads
  - Only one node can mount simultaneously
  - Pod can read and write
  - Other pods: cannot mount

ReadOnlyMany (ROX):
  - Multiple pods can mount
  - All can read, none can write
  - Useful for distributing config/data

ReadWriteMany (RWX):
  - Multiple pods can mount
  - All can read and write
  - Requires special provisioner (NFS, GlusterFS, etc.)
  - Less common in managed Kubernetes
```

---

## Scenario 6: PVC Storage Requests and Limits

**Task**: Understand PVC resource requests and resize operations.

### YAML
```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: app-pvc
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 10Gi   # Initial storage request
  storageClassName: expandable
```

### Commands for Resizing

#### Option 1: Patch Command
```bash
# Resize PVC to 20Gi (must be larger than current)
kubectl patch pvc app-pvc -p '{"spec":{"resources":{"requests":{"storage":"20Gi"}}}}'

# Verify resize request
kubectl describe pvc app-pvc
kubectl get pvc app-pvc

# Check if filesystem was auto-expanded
kubectl exec -it <pod-using-pvc> -- df -h
```

#### Option 2: Edit PVC YAML
```bash
# Edit directly
kubectl edit pvc app-pvc

# In the editor, find:
#   spec:
#     resources:
#       requests:
#         storage: 10Gi
# Change to: storage: 20Gi

# Save and exit (Ctrl+O, Ctrl+X in vi)
```

#### Option 3: Apply Updated YAML
```bash
# Modify pvc.yaml locally, then:
kubectl apply -f pvc.yaml
```

### Verification
```bash
# Check PVC status
kubectl describe pvc app-pvc

# Look for "Conditions" section
# ✓ Pending: resize requested, waiting for filesystem expansion
# ✓ FileSystemResizePending: true -> expansion in progress
# ✓ FileSystemResizePending: false -> resize complete

# Check pod view
kubectl exec -it <pod-name> -- df -h /data
```

### Resize Prerequisites
```
✓ StorageClass must have: allowVolumeExpansion: true
✓ Only increase allowed (decrease not supported)
✓ Some provisioners/filesystems may not support expansion
✓ Some filesystems require offline expansion
```

---

## Scenario 7: PVC Deletion and Cleanup

**Task**: Safely delete PVCs and manage PV reclamation.

### Deletion Scenarios

#### Scenario A: Delete PVC with Retain Policy
```bash
# Check PV reclaim policy
kubectl describe pv my-pv | grep -i reclaim

# If Retain:
kubectl delete pvc my-pvc

# PVC is deleted, PV transitions to Released state
kubectl get pv my-pv

# PV remains but is no longer claimed
# Data is preserved on underlying storage

# To reuse PV:
kubectl patch pv my-pv -p '{"spec":{"claimRef": null}}'

# PV should return to Available
kubectl get pv my-pv
```

#### Scenario B: Delete PVC with Delete Policy
```bash
# Check PV reclaim policy
kubectl describe pv my-pv | grep -i reclaim

# If Delete:
kubectl delete pvc my-pvc

# PVC is deleted, PV and underlying storage are automatically deleted
kubectl get pv my-pv  # Should be gone or in Terminating state

# After a few seconds:
kubectl get pv my-pv  # Should no longer exist
```

### Cleanup with Pod Still Running
```bash
# WARNING: Deleting in-use PVC may cause pod errors

# Step 1: Delete pod first
kubectl delete pod <pod-using-pvc>

# Step 2: Then delete PVC
kubectl delete pvc my-pvc

# Step 3: Handle PV based on reclaim policy
kubectl get pv my-pv
```

### Force Delete PVC (Last Resort)
```bash
# Remove finalizers and force delete
kubectl delete pvc my-pvc --ignore-finalizers

# Check if it worked
kubectl get pvc my-pvc
```

---

## Scenario 8: PVC in Multiple Namespaces

**Task**: Create and manage PVCs across namespaces.

### YAML
```yaml
---
# In namespace: storage-test-1
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: app-pvc
  namespace: storage-test-1
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 5Gi
  storageClassName: standard

---
# In namespace: storage-test-2
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: app-pvc
  namespace: storage-test-2
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 5Gi
  storageClassName: standard
```

### Commands
```bash
# Create namespaces
kubectl create namespace storage-test-1
kubectl create namespace storage-test-2

# Create PVCs
kubectl apply -f pvcs-multi-ns.yaml

# List PVCs in all namespaces
kubectl get pvc -A

# List PVCs in specific namespace
kubectl get pvc -n storage-test-1
kubectl get pvc -n storage-test-2

# Describe PVC in specific namespace
kubectl describe pvc app-pvc -n storage-test-1
```

### Key Points
- **PVCs are namespace-scoped**: Each namespace can have its own PVCs
- **PVs are cluster-scoped**: Shared resource, not namespace-specific
- **Isolation**: PVC in ns1 cannot be used by pod in ns2

---

## Scenario 9: Listing and Monitoring PVCs

**Task**: Effectively list, monitor, and manage PVCs.

### Common Commands
```bash
# List PVCs in current namespace
kubectl get pvc

# List PVCs in specific namespace
kubectl get pvc -n <namespace>

# List PVCs in all namespaces
kubectl get pvc -A

# List with additional columns
kubectl get pvc -o wide

# List sorted by capacity
kubectl get pvc --sort-by='.spec.resources.requests.storage'

# List with custom columns
kubectl get pvc -o custom-columns=NAME:.metadata.name,STATUS:.status.phase,VOLUME:.spec.volumeName,CAPACITY:.spec.resources.requests.storage,STORAGECLASS:.spec.storageClassName

# Get PVC in YAML format
kubectl get pvc my-pvc -o yaml

# Get PVC in JSON format
kubectl get pvc my-pvc -o json

# Describe PVC (detailed human-readable)
kubectl describe pvc my-pvc

# Watch PVC status changes
kubectl get pvc --watch

# Watch PVCs in all namespaces
kubectl get pvc -A --watch
```

### Output Interpretation
```
NAME        STATUS    VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS   AGE
my-pvc      Bound     pvc-abc123def456xyz789                     5Gi        RWO            standard       10m
pending-pvc Pending                                              2Gi        RWO            missing-class  2m
```

- **STATUS**: 
  - `Bound` — PVC has been bound to a PV
  - `Pending` — Waiting for provisioning or binding
  - `Lost` — Associated PV was deleted

- **VOLUME**: Name of the bound PV (empty if Pending)

---

## Scenario 10: PVC Events and Diagnostics

**Task**: Use events to diagnose PVC issues.

### Commands
```bash
# Get events for specific PVC
kubectl describe pvc my-pvc

# Shows Events section at bottom with:
# - What action happened
# - When it happened
# - Reason for the event

# Get all events in namespace (sorted by time)
kubectl get events -n default --sort-by='.lastTimestamp'

# Get events for all PVCs
kubectl get events -A | grep PersistentVolumeClaim

# Watch events in real-time
kubectl get events -n default --watch

# Get detailed event info
kubectl describe event <event-name>
```

### Common Events and Solutions

#### Event: "FailedBinding"
```
Reason: FailedBinding
Message: no PersistentVolumes available for this claim
```
**Solution**: Create matching PV or ensure StorageClass provisioner is running

#### Event: "ProvisioningFailed"
```
Reason: ProvisioningFailed
Message: Failed to provision volume: <error details>
```
**Solution**: Check provisioner logs, storage backend status, resource quotas

#### Event: "WaitForFirstConsumer"
```
Reason: WaitForFirstConsumer
Message: waiting for first consumer to be created
```
**Solution**: Normal for WaitForFirstConsumer volumeBindingMode; create pod to trigger binding

---

## CKA Exam Tips

- **PVC vs PV**: PVC is namespace-scoped request, PV is cluster-scoped resource
- **Binding rules matter**: Know the matching requirements (size, accessModes, storageClassName)
- **Pending diagnosis**: Master `kubectl describe pvc` to read events
- **Resize operations**: Know `allowVolumeExpansion` prerequisite
- **Deletion**: Understand `Retain` vs `Delete` policies and cleanup workflows
- **Access modes**: RWO most common, RWX requires special provisioners
- **Quick fixes**: Know how to patch PVC for common issues
- **Multi-namespace**: PVCs are namespace-scoped; each namespace gets its own claims

---

## Quick Reference

| Task | Command |
|------|---------|
| Create PVC | `kubectl apply -f pvc.yaml` |
| List PVCs | `kubectl get pvc` |
| List all namespaces | `kubectl get pvc -A` |
| Inspect PVC | `kubectl describe pvc <name>` |
| Resize PVC | `kubectl patch pvc <name> -p '{"spec":{"resources":{"requests":{"storage":"10Gi"}}}}'` |
| Delete PVC | `kubectl delete pvc <name>` |
| Get YAML | `kubectl get pvc <name> -o yaml` |
| Watch status | `kubectl get pvc --watch` |
| Events | `kubectl get events --sort-by='.lastTimestamp'` |

---

## See Also
- [Persistent Volume Claims - Kubernetes Docs](https://kubernetes.io/docs/concepts/storage/persistent-volumes/#persistentvolumeclaims)
- `scenarios/pvc/` — Detailed scenario walkthroughs
- `scenarios-pv.md` — PersistentVolume scenarios
- `storage/pvc.yaml` — PVC example
