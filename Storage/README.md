# Storage (10%) — CKA Exam Study Guide

## Overview
This section covers **Persistent Storage** in Kubernetes, a core CKA exam topic (10% of exam). Master PersistentVolumes, PersistentVolumeClaims, StorageClasses, and shared volumes.

---

## Topics Covered

### Core Concepts
1. **PersistentVolumes (PV)** — Cluster-level storage resources
2. **PersistentVolumeClaims (PVC)** — Pod requests for storage
3. **StorageClass** — Dynamic provisioning templates
4. **Access Modes** — ReadWriteOnce (RWO), ReadOnlyMany (ROX), ReadWriteMany (RWX)

### Advanced Topics
5. **PV + PVC Binding** — Static provisioning workflows
6. **Pod + PVC Integration** — Mounting volumes in Pods
7. **Volume Resizing** — Expanding PVC capacity
8. **Shared Volumes** — Multi-Pod access patterns

---

## Quick Start: 30-Second Overview

```yaml
# Step 1: StorageClass (provisioner template)
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: standard
provisioner: ebs.csi.aws.com
allowVolumeExpansion: true

---
# Step 2: PersistentVolumeClaim (request)
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: app-pvc
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 10Gi
  storageClassName: standard

---
# Step 3: Pod (uses PVC)
apiVersion: v1
kind: Pod
metadata:
  name: app-pod
spec:
  containers:
  - name: app
    image: nginx
    volumeMounts:
    - mountPath: /data
      name: storage
  volumes:
  - name: storage
    persistentVolumeClaim:
      claimName: app-pvc
```

---

## Scenario Files (Learn by Doing)

### 📖 Read These in Order

1. **[scenarios-pv.md](./scenarios-pv.md)** ← Start here
   - Creating static and dynamic PersistentVolumes
   - Understanding reclaim policies (Retain, Delete)
   - Access modes and NFS volumes
   - Troubleshooting PV issues

2. **[scenarios-storage-class.md](./scenarios-storage-class.md)**
   - Creating and configuring StorageClasses
   - Cloud provider specifics (AWS, GCP, Azure)
   - Dynamic provisioning
   - Default StorageClass setup

3. **[scenarios-pvc.md](./scenarios-pvc.md)**
   - Creating PersistentVolumeClaims
   - Static vs dynamic binding
   - Troubleshooting pending PVCs
   - PVC access modes and resizing

4. **[scenarios-pv-pvc.md](./scenarios-pv-pvc.md)**
   - Complete PV + PVC workflow
   - Binding matching rules (capacity, accessMode, storageClass)
   - Partial binding and capacity planning
   - Debugging binding failures

5. **[scenarios-pvc-pod.md](./scenarios-pvc-pod.md)**
   - Mounting PVCs in Pods
   - Data persistence verification
   - Multiple containers sharing volumes
   - Using subPath for isolation
   - Pod initialization with initContainers

6. **[scenarios-pvc-resize.md](./scenarios-pvc-resize.md)**
   - Expanding PVC capacity
   - Monitoring resize operations
   - Troubleshooting resize failures
   - Automated resize detection

7. **[scenarios-shared-volume.md](./scenarios-shared-volume.md)** ← Advanced
   - Shared volumes for multiple Pods
   - NFS-based storage
   - Configuration distribution patterns
   - Performance considerations
   - Multi-Pod write scenarios

---

## Common Commands

### List Resources
```bash
# Persistent Volumes
kubectl get pv
kubectl get pv -o wide
kubectl describe pv <name>

# Persistent Volume Claims
kubectl get pvc
kubectl get pvc -A
kubectl describe pvc <name> -n <namespace>

# Storage Classes
kubectl get storageclass
kubectl describe sc <name>
```

### Create and Apply
```bash
# From YAML files
kubectl apply -f pv.yaml
kubectl apply -f storageclass.yaml
kubectl apply -f pvc.yaml

# Dynamic provisioning (PVC auto-creates PV)
kubectl apply -f pvc-dynamic.yaml
```

### Troubleshooting
```bash
# Check PVC status and events
kubectl describe pvc <name>

# Check if PVC is bound to PV
kubectl get pvc <name> -o jsonpath='{.spec.volumeName}'

# Get PV details
kubectl describe pv <pv-name>

# View events (often show binding/provisioning issues)
kubectl get events --sort-by='.lastTimestamp'

# Check StorageClass provisioner
kubectl get sc <name> -o jsonpath='{.provisioner}'
```

### Resizing
```bash
# Resize a PVC (if StorageClass allows expansion)
kubectl patch pvc <name> -p '{"spec":{"resources":{"requests":{"storage":"20Gi"}}}}'

# Monitor resize status
kubectl describe pvc <name> | grep -A 5 Conditions
```

### Mounting in Pods
```bash
# Check volume mounts inside Pod
kubectl exec <pod> -- df -h

# Read/write files on mounted volume
kubectl exec <pod> -- cat /data/file.txt
kubectl exec <pod> -- sh -c 'echo data > /data/file.txt'
```

---

## Key Concepts Summary

### Access Modes
```
ReadWriteOnce (RWO)  - Single Pod, read/write (default, most common)
ReadOnlyMany (ROX)   - Multiple Pods, read-only
ReadWriteMany (RWX)  - Multiple Pods, read/write (needs NFS/CSI)
```

### Reclaim Policies
```
Retain  - Keep PV after PVC deletion (manual cleanup needed)
Delete  - Auto-delete PV when PVC deleted (cloud default)
Recycle - Deprecated; don't use
```

### Volume Binding Modes
```
Immediate              - Provision PV immediately (default)
WaitForFirstConsumer   - Provision only when Pod scheduled (multi-zone)
```

### StorageClass Parameters
```
provisioner              - What provisions the PV (e.g., ebs.csi.aws.com)
allowVolumeExpansion     - Can PVC be resized? (true/false)
reclaimPolicy            - What happens to PV when PVC deleted?
volumeBindingMode        - When to provision (Immediate/WaitForFirstConsumer)
parameters               - Provisioner-specific settings
```

---

## Static vs Dynamic Provisioning

### Static (Manual PV Creation)
```
Admin creates PV manually
  ↓
User creates PVC
  ↓
Kubernetes matches and binds PV to PVC
  ↓
Pod uses PVC
```
**Use case**: Labs, existing storage systems

### Dynamic (StorageClass)
```
Admin creates StorageClass
  ↓
User creates PVC with storageClassName
  ↓
Provisioner automatically creates PV
  ↓
PVC automatically binds to new PV
  ↓
Pod uses PVC
```
**Use case**: Cloud environments, large deployments

---

## Storage Flow Diagram

```
┌─────────────────────────────────────────────────┐
│  StorageClass (provisioner blueprint)           │
│  - provisioner: ebs.csi.aws.com                 │
│  - allowVolumeExpansion: true                    │
│  - reclaimPolicy: Delete                        │
└─────────────────────────────────────────────────┘
                      ↓
┌─────────────────────────────────────────────────┐
│  PersistentVolume (cluster resource)            │
│  - capacity: 10Gi                               │
│  - accessModes: [ReadWriteOnce]                 │
│  - storageClassName: standard                   │
│  STATUS: Available                              │
└─────────────────────────────────────────────────┘
                      ↓ (binding)
┌─────────────────────────────────────────────────┐
│  PersistentVolumeClaim (namespace resource)     │
│  - requests: 10Gi                               │
│  - accessModes: [ReadWriteOnce]                 │
│  - storageClassName: standard                   │
│  STATUS: Bound (volumeName: pv-abc123)         │
└─────────────────────────────────────────────────┘
                      ↓ (mounted in)
┌─────────────────────────────────────────────────┐
│  Pod                                            │
│  containers:                                    │
│  - volumeMounts:                                │
│    - mountPath: /data                           │
│      name: storage                              │
│  volumes:                                       │
│  - name: storage                                │
│    persistentVolumeClaim:                       │
│      claimName: app-pvc                         │
└─────────────────────────────────────────────────┘
```

---

## Exam Tips & Gotchas

### Know These Differences
- **PV is cluster-scoped** — Shared by all namespaces
- **PVC is namespace-scoped** — Each namespace has its own PVCs
- **One PV = One PVC** — Multiple PVCs can't share single PV (even with RWX, one PV binds one PVC)
- **Multiple Pods can mount same PVC if RWX** — But only via one PVC to one PV

### Common Mistakes to Avoid
- ❌ Creating PVC with non-existent StorageClass
- ❌ Requesting PVC size > available PV size
- ❌ Expecting RWX access mode from RWO provisioner
- ❌ Using hostPath PV in multi-node cluster (not portable)
- ❌ Trying to shrink PVC (only increases allowed)
- ❌ Forgetting to mount volume in pod.spec.volumes

### Must-Know Troubleshooting
```bash
# PVC stuck in Pending?
→ Check: StorageClass exists
→ Check: PV available (if static)
→ Check: Capacity matches
→ Check: Provisioner logs (if dynamic)

# Pod can't write to volume?
→ Check: accessModes compatible
→ Check: fsGroup permissions
→ Check: mountPath exists in container

# Resize not working?
→ Check: StorageClass has allowVolumeExpansion: true
→ Check: New size > current size (can't shrink)
→ Check: Provisioner supports expansion
```

---

## Practice Checklist

- [ ] Create PV with hostPath and verify Available status
- [ ] Create PVC and bind to PV, verify Bound status
- [ ] Create StorageClass and PVC, watch dynamic PV provisioning
- [ ] Mount PVC in Pod and write/read files
- [ ] Verify data persists after Pod restart
- [ ] Delete Pod, recreate with same PVC, data persists
- [ ] Set default StorageClass
- [ ] Resize PVC and verify filesystem expansion
- [ ] Troubleshoot PVC stuck in Pending state
- [ ] Create multiple Pods with RWX volume, verify data sharing

---

## Reference Files

### YAML Templates in `storage/` folder
- `pv-hostpath.yaml` — Static HostPath PV example
- `pvc.yaml` — PersistentVolumeClaim example
- `storageclass.yaml` — StorageClass example

### Detailed Scenario Walkthroughs
- `scenarios/pv/` — PV scenarios with step-by-step walkthrough
- `scenarios/pvc/` — PVC scenarios
- `scenarios/storage-class/` — StorageClass scenarios
- `scenarios/pv-pvc/` — PV + PVC binding scenarios
- `scenarios/pvc-pod/` — Pod integration scenarios
- `scenarios/pvc-resize/` — Volume resize scenarios
- `scenarios/sc-pv-pvc-pod/` — End-to-end workflow
- `scenarios/shared-volume/` — Multi-Pod shared volume scenarios

---

## External Resources

- **Official Kubernetes Docs**: https://kubernetes.io/docs/concepts/storage/
- **Storage Classes**: https://kubernetes.io/docs/concepts/storage/storage-classes/
- **Persistent Volumes**: https://kubernetes.io/docs/concepts/storage/persistent-volumes/
- **Persistent Volume Claims**: https://kubernetes.io/docs/concepts/storage/persistent-volumes/#persistentvolumeclaims

---

## CKA Exam Breakdown (Storage 10%)

Topics typically tested:
1. **PV Creation** (5%)
   - Static provisioning with hostPath, NFS, local
   - Understanding capacity and access modes
   - Reclaim policies

2. **PVC Creation & Binding** (3%)
   - Creating PVCs
   - Matching PV requirements
   - Troubleshooting binding issues

3. **StorageClass & Dynamic Provisioning** (2%)
   - Creating StorageClass
   - PVC triggers PV creation
   - Default StorageClass

4. **Pod & Volume Integration** (4%)
   - Mounting PVC in Pod
   - Persistence verification
   - Multi-container volume sharing
   - Shared volumes (RWX)

5. **Advanced Operations** (1%)
   - PVC resizing
   - Volume troubleshooting
   - Performance considerations

---

## Next Steps After This Section

Once you master Storage:
1. Study **Workloads & Scheduling** (using storage in Deployments, StatefulSets)
2. Study **Cluster Architecture** (resource management with storage)
3. Study **Services & Networking** (storage backends for stateful services)

---

**Last Updated**: 2024
**For CKA Exam**: Version 1.30+

