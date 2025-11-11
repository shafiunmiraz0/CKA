# PersistentVolume (PV) — Scenarios & Commands

## Overview
A **PersistentVolume (PV)** is a cluster-level storage resource that exists independently of any Pod. PVs abstract the details of how storage is provided, whether from cloud providers, NFS, hostPath, or local storage.

---

## Scenario 1: Create a Static HostPath PV

**Task**: Create a static PersistentVolume using hostPath (suitable for single-node lab environments).

### YAML
```yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: pv-hostpath
spec:
  capacity:
    storage: 5Gi
  accessModes:
    - ReadWriteOnce
  persistentVolumeReclaimPolicy: Retain
  storageClassName: manual
  hostPath:
    path: /mnt/data/pv-hostpath
```

### Commands
```bash
# Create PV
kubectl apply -f pv-hostpath.yaml

# Verify PV is created and available
kubectl get pv
kubectl describe pv pv-hostpath

# Inspect PV details including status and binding
kubectl get pv -o wide
kubectl get pv pv-hostpath -o yaml
```

### Verification
- **Status**: PV should show `Available` initially.
- **Capacity**: Should display `5Gi`.
- **Access Modes**: Should list `RWO` (ReadWriteOnce).

### Key Concepts
- **Reclaim Policy**: `Retain` — keeps the volume after PVC deletion (manual cleanup).
- **Storage Class**: `manual` — static provisioning; no dynamic provisioner.
- **Host Path**: Only suitable for single-node clusters; requires the path to exist on the node.

---

## Scenario 2: PV Reclaim Policies

**Task**: Understand different PV reclaim policies and their behavior.

### Reclaim Policy Types

#### Retain
```yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: pv-retain
spec:
  capacity:
    storage: 2Gi
  accessModes:
    - ReadWriteOnce
  persistentVolumeReclaimPolicy: Retain  # Data kept after PVC deletion
  storageClassName: manual
  hostPath:
    path: /mnt/data/pv-retain
```
- **Behavior**: When PVC is deleted, the PV remains in `Released` state. Admin must manually clean up.
- **Use Case**: When you need to preserve data even after PVC deletion.

#### Delete
```yaml
persistentVolumeReclaimPolicy: Delete  # Volume deleted when PVC is deleted
```
- **Behavior**: When PVC is deleted, the PV and underlying storage are automatically deleted.
- **Use Case**: Cloud-managed storage (EBS, GCE PD) where cloud provider deletes resources.

#### Recycle
- **Deprecated** in Kubernetes 1.15+; use `Retain` or `Delete` instead.

### Commands to Test Reclaim Policy
```bash
# Create PVC from PV with Retain policy
kubectl apply -f pvc-retain.yaml

# Delete the PVC
kubectl delete pvc pvc-retain

# PV should now be in Released state
kubectl get pv pv-retain

# Manually clean up data (for Retain policy)
# ssh into node: rm -rf /mnt/data/pv-retain

# After cleanup, reset PV to Available
kubectl patch pv pv-retain -p '{"spec":{"claimRef": null}}'

# Verify PV is Available again
kubectl get pv pv-retain
```

---

## Scenario 3: Access Modes

**Task**: Understand PV access modes and their constraints.

### Access Modes
```yaml
accessModes:
  - ReadWriteOnce     # RWO: Single pod read/write (most common)
  - ReadOnlyMany      # ROX: Multiple pods read-only
  - ReadWriteMany     # RWX: Multiple pods read/write (requires special provisioner)
```

### YAML Example: Different Access Modes
```yaml
---
# Single pod read/write
apiVersion: v1
kind: PersistentVolume
metadata:
  name: pv-rwo
spec:
  capacity:
    storage: 2Gi
  accessModes:
    - ReadWriteOnce
  storageClassName: manual
  hostPath:
    path: /mnt/data/rwo

---
# Multiple pods read-only
apiVersion: v1
kind: PersistentVolume
metadata:
  name: pv-rox
spec:
  capacity:
    storage: 2Gi
  accessModes:
    - ReadOnlyMany
  storageClassName: manual
  hostPath:
    path: /mnt/data/rox

---
# Multiple pods read/write (requires NFS or CSI provisioner)
apiVersion: v1
kind: PersistentVolume
metadata:
  name: pv-rwx
spec:
  capacity:
    storage: 2Gi
  accessModes:
    - ReadWriteMany
  storageClassName: nfs
  nfs:
    server: 192.168.1.100
    path: /exports/data
```

### Commands
```bash
# Create PVs with different access modes
kubectl apply -f pv-access-modes.yaml

# List PVs with access modes
kubectl get pv
kubectl describe pv pv-rwo

# When binding PVC to PV, accessModes must be compatible
# PVC requests must match PV's supported modes
```

---

## Scenario 4: NFS-Based PV

**Task**: Create a PersistentVolume backed by NFS for shared storage.

### YAML
```yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: pv-nfs
spec:
  capacity:
    storage: 10Gi
  accessModes:
    - ReadWriteMany
  storageClassName: nfs
  nfs:
    server: 192.168.1.100          # NFS server IP
    path: /exports/kubernetes-data # NFS export path
    readOnly: false                # Allow write access
```

### Commands
```bash
# Create NFS PV
kubectl apply -f pv-nfs.yaml

# Verify
kubectl get pv pv-nfs
kubectl describe pv pv-nfs

# Check NFS server connectivity (from node)
# showmount -e 192.168.1.100
```

### Verification Checklist
- [ ] NFS server is running and accessible
- [ ] Export path exists on NFS server
- [ ] Kubernetes nodes can reach NFS server
- [ ] PV shows correct capacity and access modes

---

## Scenario 5: Local PV (Node-Affinity)

**Task**: Create a PersistentVolume bound to a specific node using `nodeAffinity`.

### YAML
```yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: pv-local
spec:
  capacity:
    storage: 20Gi
  accessModes:
    - ReadWriteOnce
  storageClassName: local-storage
  local:
    path: /mnt/local-storage/data
  nodeAffinity:
    required:
      nodeSelectorTerms:
      - matchExpressions:
        - key: kubernetes.io/hostname
          operator: In
          values:
          - worker-node-1  # Bind to specific node
```

### Commands
```bash
# Create local PV
kubectl apply -f pv-local.yaml

# Verify node affinity
kubectl describe pv pv-local

# PVC must be on same node as local PV
kubectl get pv pv-local -o yaml | grep -A 5 nodeAffinity
```

### Key Points
- **Local volumes** are bound to specific nodes.
- **PVCs** must be scheduled on the same node.
- **Pod affinity rules** should enforce pod scheduling on the correct node.

---

## Scenario 6: Listing and Inspecting PVs

**Task**: Efficiently manage and monitor PersistentVolumes.

### Common Commands
```bash
# List all PVs
kubectl get pv

# List with additional columns (size, access mode, reclaim policy)
kubectl get pv -o wide

# Get PV details in YAML format
kubectl get pv pv-hostpath -o yaml

# Get PV details in JSON format
kubectl get pv pv-hostpath -o json

# Describe PV (human-readable)
kubectl describe pv pv-hostpath

# List PVs sorted by capacity
kubectl get pv --sort-by=.spec.capacity.storage

# List PVs with specific label
kubectl get pv -l storage-type=fast

# Monitor PV status in real-time
kubectl get pv --watch
```

### Output Interpretation
```
NAME        CAPACITY  ACCESS MODES  RECLAIM POLICY  STATUS    CLAIM       CLASS    REASON
pv-hostpath 5Gi       RWO           Retain          Bound     ns/my-pvc   manual
pv-nfs      10Gi      RWX           Delete          Released            nfs
```

- **STATUS**: Available (free), Bound (claimed by PVC), Released (PVC deleted, reclaim pending)
- **CLAIM**: Shows which namespace/PVC has claimed this PV
- **CLASS**: StorageClass reference

---

## Scenario 7: Deleting and Cleaning Up PVs

**Task**: Safely delete PersistentVolumes and reclaim storage.

### Commands
```bash
# Delete a PV (if not claimed by a PVC)
kubectl delete pv pv-hostpath

# Force delete a PV (not recommended if data is important)
kubectl delete pv pv-hostpath --force

# If PV is in Released state (Retain policy)
# Step 1: Clean up underlying storage (node-specific)
#   For hostPath: ssh into node and rm -rf /mnt/data/pv-hostpath

# Step 2: Reset PV to Available (if reusing)
kubectl patch pv pv-hostpath -p '{"spec":{"claimRef": null}}'

# Step 3: Verify
kubectl get pv pv-hostpath

# Delete all PVs (dangerous - will lose data if no backup)
kubectl delete pv --all
```

### Safe Deletion Workflow
```bash
# 1. Identify PVC using the PV
kubectl describe pv pv-hostpath | grep -i claim

# 2. Delete the PVC first
kubectl delete pvc <pvc-name> -n <namespace>

# 3. Verify PV status changed to Released
kubectl get pv pv-hostpath

# 4. For Retain policy, clean up data manually, then delete PV
kubectl delete pv pv-hostpath

# 5. For Delete policy, cloud resources should auto-delete
kubectl get pv pv-hostpath  # Should be gone
```

---

## Scenario 8: Troubleshooting PV Issues

### Issue 1: PV Not Appearing as Available

```bash
# Check PV status
kubectl describe pv pv-hostpath

# Look for:
# - STATUS: Should be "Available" or "Bound"
# - If "Released": PV has Retain policy and needs manual cleanup
```

**Solution**:
```bash
# For Retain policy, reset claimRef
kubectl patch pv pv-hostpath -p '{"spec":{"claimRef": null}}'
```

### Issue 2: HostPath PV with File Not Found

```bash
# Error: "hostPath type check failed: /mnt/data does not exist"

# Solution: Create directory on node
# SSH into node first
mkdir -p /mnt/data/pv-hostpath
chmod 755 /mnt/data/pv-hostpath
```

### Issue 3: NFS PV Connection Fails

```bash
# Test NFS connectivity (from Kubernetes node)
showmount -e 192.168.1.100

# Check if NFS path is mounted
mount | grep nfs

# Manually mount for testing
mount -t nfs 192.168.1.100:/exports/data /mnt/test
```

### Issue 4: PVC Stays Pending When Binding to PV

```bash
# Check for size mismatch
kubectl describe pvc my-pvc

# PVC must request <= PV size
# PVC accessModes must be subset of PV accessModes
# PVC storageClassName must match PV storageClassName
```

---

## CKA Exam Tips

- **Know the difference**: PV (cluster resource) vs PVC (namespace resource)
- **Reclaim policies matter**: `Retain` for safety, `Delete` for cloud managed
- **AccessModes**: Most tests use `ReadWriteOnce`, but know `ReadWriteMany` requires special provisioners
- **HostPath limitations**: Works in single-node labs, not production-ready for multi-node
- **Troubleshooting**: Master `kubectl describe pv` and `kubectl describe pvc` for debugging binding issues
- **Quick cleanup**: Know how to reset PV claimRef for reuse
- **Storage classes**: PV can be static (manual creation) or dynamic (provisioner-based)

---

## Quick Reference

| Task | Command |
|------|---------|
| Create PV | `kubectl apply -f pv.yaml` |
| List PVs | `kubectl get pv` |
| Inspect PV | `kubectl describe pv <name>` |
| Delete PV | `kubectl delete pv <name>` |
| Reset claimRef | `kubectl patch pv <name> -p '{"spec":{"claimRef": null}}'` |
| Get PV YAML | `kubectl get pv <name> -o yaml` |
| Sort by capacity | `kubectl get pv --sort-by=.spec.capacity.storage` |
| Watch PVs | `kubectl get pv --watch` |

---

## See Also
- [Persistent Volumes - Kubernetes Docs](https://kubernetes.io/docs/concepts/storage/persistent-volumes/)
- `scenarios/pv/` — Detailed scenario walkthroughs
- `storage/pv-hostpath.yaml` — HostPath PV example
