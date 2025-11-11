# PersistentVolume + PersistentVolumeClaim — Integration Scenarios

## Overview
This document covers the **static provisioning workflow**: creating a PersistentVolume, binding it to a PersistentVolumeClaim, and understanding the matching requirements.

---

## Scenario 1: Complete PV + PVC Workflow

**Task**: Create a static PV, bind it to a PVC, and verify the relationship.

### Step 1: Create a Static PersistentVolume
```yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: app-pv
spec:
  capacity:
    storage: 5Gi
  accessModes:
    - ReadWriteOnce
  storageClassName: manual
  persistentVolumeReclaimPolicy: Retain
  hostPath:
    path: /mnt/data/app
```

### Step 2: Create a PersistentVolumeClaim
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
      storage: 5Gi
  storageClassName: manual
```

### Step 3: Apply and Verify
```bash
# Create the PV
kubectl apply -f pv.yaml

# Verify PV is Available
kubectl get pv app-pv

# Create the PVC
kubectl apply -f pvc.yaml

# Verify PVC is Bound and PV is Bound
kubectl get pvc app-pvc
kubectl get pv app-pv

# Both should show status Bound
kubectl describe pvc app-pvc
kubectl describe pv app-pv

# Check binding details
kubectl get pvc app-pvc -o yaml | grep volumeName
kubectl get pv app-pv -o yaml | grep claimRef -A 3
```

### Expected Output
```bash
# kubectl get pvc app-pvc
NAME      STATUS   VOLUME   CAPACITY   ACCESS MODES   STORAGECLASS   AGE
app-pvc   Bound    app-pv   5Gi        RWO            manual         2m

# kubectl get pv app-pv
NAME     CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS   CLAIM             STORAGECLASS   REASON   AGE
app-pv   5Gi        RWO            Retain           Bound    default/app-pvc   manual                  5m
```

---

## Scenario 2: Understanding Binding Matching Rules

**Task**: Verify that PV and PVC matching rules are correctly applied.

### Matching Requirements
```
PVC Request ← Must Match → PV Specification

1. storageClassName: PVC storageClassName = PV storageClassName
2. Capacity: PVC storage request ≤ PV capacity
3. Access Modes: PVC accessModes ⊆ PV accessModes (subset)
```

### Test Case 1: Matching StorageClassName

#### Failing Case
```yaml
# PV with storageClassName: manual
apiVersion: v1
kind: PersistentVolume
metadata:
  name: pv-manual
spec:
  storageClassName: manual
  capacity:
    storage: 5Gi
  # ...

---
# PVC with storageClassName: fast (mismatch)
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: pvc-fast
spec:
  storageClassName: fast  # MISMATCH!
  resources:
    requests:
      storage: 5Gi
```

```bash
# Result: PVC stays Pending
kubectl get pvc pvc-fast

# Fix: Update PVC storageClassName
kubectl patch pvc pvc-fast -p '{"spec":{"storageClassName":"manual"}}'

# PVC now binds
kubectl get pvc pvc-fast
```

### Test Case 2: Matching Capacity

#### Failing Case
```yaml
# PV with 5Gi capacity
apiVersion: v1
kind: PersistentVolume
metadata:
  name: pv-small
spec:
  capacity:
    storage: 5Gi
  # ...

---
# PVC requesting 10Gi (more than PV)
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: pvc-large
spec:
  resources:
    requests:
      storage: 10Gi  # MISMATCH! (> PV capacity)
```

```bash
# Result: PVC stays Pending
kubectl get pvc pvc-large
kubectl describe pvc pvc-large

# Look for: "no PersistentVolume available for this claim"

# Fix: Create larger PV or reduce PVC request
kubectl patch pvc pvc-large -p '{"spec":{"resources":{"requests":{"storage":"5Gi"}}}}'

# PVC now binds
kubectl get pvc pvc-large
```

### Test Case 3: Matching Access Modes

#### Failing Case
```yaml
# PV with single ReadWriteOnce
apiVersion: v1
kind: PersistentVolume
metadata:
  name: pv-rwo
spec:
  accessModes:
    - ReadWriteOnce
  # ...

---
# PVC requesting ReadWriteMany (not available in PV)
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: pvc-rwx
spec:
  accessModes:
    - ReadWriteMany  # MISMATCH! (PV doesn't support)
```

```bash
# Result: PVC stays Pending
kubectl get pvc pvc-rwx
kubectl describe pvc pvc-rwx

# Fix: Update PVC to use subset of PV's access modes
kubectl patch pvc pvc-rwx -p '{"spec":{"accessModes":["ReadWriteOnce"]}}'

# PVC now binds
kubectl get pvc pvc-rwx
```

---

## Scenario 3: Partial Binding (PVC < PV)

**Task**: Bind a PVC that requests less storage than the PV provides.

### YAML
```yaml
---
apiVersion: v1
kind: PersistentVolume
metadata:
  name: pv-large
spec:
  capacity:
    storage: 100Gi  # Large PV
  accessModes:
    - ReadWriteOnce
  storageClassName: standard
  hostPath:
    path: /mnt/data/large

---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: app-pvc
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 10Gi  # Requesting only 10Gi from 100Gi PV
  storageClassName: standard
```

### Commands
```bash
# Create both
kubectl apply -f pv-large.yaml
kubectl apply -f pvc-small.yaml

# Verify binding
kubectl get pv pv-large
kubectl get pvc app-pvc

# Both should be Bound
# PVC shows 10Gi request, PV shows 100Gi capacity
kubectl describe pv pv-large   # Shows PV capacity 100Gi, bound to app-pvc
kubectl describe pvc app-pvc   # Shows requested 10Gi
```

### Key Point
- Once a PVC binds to a PV, even if PVC requests 10Gi and PV has 100Gi, only 10Gi is allocated to that PVC
- The remaining 90Gi is reserved by the binding (not available for other PVCs)
- This is why you typically want PVC size ≈ PV size

---

## Scenario 4: Unbinding and Rebinding

**Task**: Understand how to unbind and rebind PV and PVC.

### Scenario A: Delete PVC, Rebind PV

```bash
# Initial state: PV and PVC are Bound
kubectl get pv app-pv
kubectl get pvc app-pvc

# Delete PVC
kubectl delete pvc app-pvc

# PV now shows Released status
kubectl get pv app-pv
# STATUS: Released
# CLAIM: (empty)

# For Retain policy, reset claimRef to Available
kubectl patch pv app-pv -p '{"spec":{"claimRef": null}}'

# PV should return to Available
kubectl get pv app-pv

# Now create a new PVC (with same specs) to rebind
kubectl apply -f pvc-new.yaml

# PV binds to new PVC
kubectl get pv app-pv
kubectl get pvc pvc-new
```

### Scenario B: Multiple PVs, Single PVC

```bash
# Scenario: What if multiple PVs match the PVC?
# Kubernetes uses first Available match (by creation order)

# Create PV-A
kubectl apply -f pv-a.yaml

# Create PV-B (same specs)
kubectl apply -f pv-b.yaml

# Create PVC matching both
kubectl apply -f pvc.yaml

# Result: PVC binds to PV-A (created first)
kubectl get pvc my-pvc -o yaml | grep volumeName
# volumeName: pv-a

# To bind to PV-B:
# Option 1: Delete PVC and PV-A, recreate PVC
# Option 2: Manually set claimRef in PV-B to point to PVC
```

---

## Scenario 5: Multiple PVCs, Single PV

**Task**: Understand why a PV can bind to only one PVC.

### YAML
```yaml
---
apiVersion: v1
kind: PersistentVolume
metadata:
  name: shared-pv
spec:
  capacity:
    storage: 20Gi
  accessModes:
    - ReadWriteMany  # Supports multiple mounts
  storageClassName: nfs
  nfs:
    server: 192.168.1.100
    path: /exports/data

---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: pvc-a
spec:
  accessModes:
    - ReadWriteMany
  resources:
    requests:
      storage: 10Gi
  storageClassName: nfs

---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: pvc-b
spec:
  accessModes:
    - ReadWriteMany
  resources:
    requests:
      storage: 10Gi
  storageClassName: nfs
```

### Commands
```bash
# Create PV
kubectl apply -f pv-shared.yaml

# Create PVC-A
kubectl apply -f pvc-a.yaml

# PV binds to PVC-A
kubectl get pv shared-pv   # STATUS: Bound
kubectl get pvc pvc-a      # STATUS: Bound

# Create PVC-B
kubectl apply -f pvc-b.yaml

# PVC-B stays Pending (PV already bound)
kubectl get pvc pvc-b      # STATUS: Pending
kubectl describe pvc pvc-b

# Even though PV has 20Gi and both PVCs want 10Gi each,
# a PV can only bind to ONE PVC

# To satisfy PVC-B, create another PV
kubectl apply -f pv-shared-2.yaml

# Now PVC-B binds
kubectl get pvc pvc-b      # STATUS: Bound
```

### Key Point
- **One PV = One PVC**: A PersistentVolume can only be bound to one PersistentVolumeClaim
- **Multiple accessModes don't help**: Even with ReadWriteMany, still one PVC per PV
- **Solution**: Create multiple PVs for multiple PVCs

---

## Scenario 6: Debugging Binding Issues

**Task**: Diagnose why PV and PVC won't bind.

### Debugging Workflow
```bash
# Step 1: Check PVC status
kubectl get pvc app-pvc
# If Pending, investigate further

# Step 2: Check PVC details and events
kubectl describe pvc app-pvc

# Look for:
# - Events section at bottom
# - Error messages about provisioner, storage class, or matching

# Step 3: Check if PV exists and is Available
kubectl get pv

# Step 4: Verify matching requirements
echo "PVC storageClassName:"
kubectl get pvc app-pvc -o jsonpath='{.spec.storageClassName}'

echo "PV storageClassName:"
kubectl get pv app-pv -o jsonpath='{.spec.storageClassName}'

# Step 5: Check capacity
echo "PVC capacity request:"
kubectl get pvc app-pvc -o jsonpath='{.spec.resources.requests.storage}'

echo "PV capacity:"
kubectl get pv app-pv -o jsonpath='{.spec.capacity.storage}'

# Step 6: Check access modes
echo "PVC access modes:"
kubectl get pvc app-pvc -o jsonpath='{.spec.accessModes}'

echo "PV access modes:"
kubectl get pv app-pv -o jsonpath='{.spec.accessModes}'
```

### Common Issues and Fixes

#### Issue 1: "no PersistentVolumes available"
```bash
# Cause: No matching PV exists or all PVs are bound

# Fix 1: Create a matching PV
kubectl apply -f matching-pv.yaml

# Fix 2: Check if PVs exist
kubectl get pv

# Fix 3: Delete another PVC to free up a PV
kubectl delete pvc other-pvc
```

#### Issue 2: "FailedBinding"
```bash
# Cause: Binding failed (mismatched storageClassName, size, or accessModes)

# Debug:
kubectl describe pvc app-pvc

# Check all three matching requirements
kubectl get pvc app-pvc -o jsonpath='{.spec}' | jq
kubectl get pv app-pv -o jsonpath='{.spec}' | jq
```

#### Issue 3: "WaitForFirstConsumer"
```bash
# Cause: StorageClass using WaitForFirstConsumer mode (normal for multi-zone clusters)

# Fix: Create a pod that uses the PVC
kubectl apply -f pod-using-pvc.yaml

# PVC will bind after pod is scheduled
```

---

## Scenario 7: Performance and Optimization

**Task**: Best practices for PV and PVC sizing and binding.

### Right-Sizing PV and PVC
```yaml
# ❌ WRONG: PV much larger than PVC
apiVersion: v1
kind: PersistentVolume
metadata:
  name: pv-huge
spec:
  capacity:
    storage: 1000Gi  # Wasteful if PVC only requests 10Gi

---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: pvc-small
spec:
  resources:
    requests:
      storage: 10Gi
```

```yaml
# ✓ RIGHT: PV size matches PVC request
apiVersion: v1
kind: PersistentVolume
metadata:
  name: pv-right-sized
spec:
  capacity:
    storage: 10Gi

---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: pvc-matched
spec:
  resources:
    requests:
      storage: 10Gi
```

### Optimization Tips
```bash
# 1. Create PVs with various sizes to accommodate different workloads
kubectl apply -f pv-1gb.yaml  pv-5gb.yaml  pv-10gb.yaml

# 2. Use StorageClasses for different performance tiers
kubectl apply -f sc-fast.yaml  sc-standard.yaml  sc-slow.yaml

# 3. List PVs to see utilization
kubectl get pv -o custom-columns=NAME:.metadata.name,CAPACITY:.spec.capacity.storage,CLAIM:.spec.claimRef.name,STATUS:.status.phase

# 4. Identify unused PVs (in Available state)
kubectl get pv --field-selector=status.phase=Available
```

---

## CKA Exam Tips

- **Binding is automatic**: If specs match, PVC automatically binds to PV
- **Matching rules are strict**: All three (storageClassName, capacity, accessModes) must match
- **PV singleton**: One PV can only bind to one PVC; if you need multiple PVCs, create multiple PVs
- **Reclaim matters**: For Retain policy, know how to reset claimRef for rebinding
- **Pending diagnosis**: Use `kubectl describe pvc` to see matching failure reasons
- **Capacity awareness**: PVC can request less than PV has, but PV becomes fully allocated to that PVC
- **Static provisioning**: Main use case in multi-node labs where dynamic provisioners aren't available

---

## Quick Reference

| Task | Command |
|------|---------|
| Create PV | `kubectl apply -f pv.yaml` |
| Create PVC | `kubectl apply -f pvc.yaml` |
| Check binding | `kubectl get pv,pvc` |
| Verify match | `kubectl describe pvc <name>` + `kubectl describe pv <name>` |
| Reset claimRef | `kubectl patch pv <name> -p '{"spec":{"claimRef": null}}'` |
| Check capacity | `kubectl get pv <name> -o jsonpath='{.spec.capacity.storage}'` |
| Check accessModes | `kubectl get pv <name> -o jsonpath='{.spec.accessModes}'` |
| Check events | `kubectl describe pvc <name> \| tail -20` |

---

## See Also
- `scenarios-pv.md` — Detailed PV scenarios
- `scenarios-pvc.md` — Detailed PVC scenarios
- `scenarios/pv-pvc/` — Scenario walkthroughs
