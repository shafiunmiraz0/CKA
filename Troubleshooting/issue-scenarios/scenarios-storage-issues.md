# Resource & Storage Troubleshooting Scenarios: PV and PVC

## PersistentVolume Issue: PV Stuck in Available

**Symptoms:**
- PV status is `Available` but PVC stays `Pending`
- PVC cannot bind to PV
- PV age increasing but not in use

## Quick Diagnosis
```bash
# Check PV status
kubectl get pv

# Output example:
# NAME    CAPACITY ACCESSMODE RECLAIMPOLICY STATUS    CLAIM
# pv-1    10Gi     RWO        Delete        Available  (← Problem)

# Detailed PV info
kubectl describe pv <pv-name>

# Check related PVC
kubectl get pvc -A

# Check events on PV
kubectl describe pv <pv-name> | grep -A 10 "Events"
```

## Common Causes & Fixes

### Cause 1: Access Mode Mismatch
```bash
# Check PV access modes
kubectl get pv <pv-name> -o jsonpath='{.spec.accessModes}'
# Output: ["ReadOnlyMany"]  (← Problem if PVC needs RWO)

# Check PVC access mode needed
kubectl get pvc <pvc-name> -o jsonpath='{.spec.accessModes}'

# Common access modes:
# ReadWriteOnce (RWO) - single node read/write
# ReadOnlyMany (ROX) - many nodes read
# ReadWriteMany (RWX) - many nodes read/write

# Fix: Create new PV with correct access mode
# or recreate PVC with matching access mode

# Example PV with RWO:
apiVersion: v1
kind: PersistentVolume
metadata:
  name: pv-rwo
spec:
  capacity:
    storage: 10Gi
  accessModes:
    - ReadWriteOnce  # ← Correct mode
  persistentVolumeReclaimPolicy: Delete
  hostPath:
    path: /mnt/data
```

### Cause 2: Storage Class Mismatch
```bash
# Check PV storage class
kubectl get pv <pv-name> -o jsonpath='{.spec.storageClassName}'

# Check PVC storage class needed
kubectl get pvc <pvc-name> -o jsonpath='{.spec.storageClassName}'

# If empty in PV but specified in PVC, they won't bind
# Fix: Either add storageClassName to PV:

kubectl patch pv <pv-name> -p '{"spec":{"storageClassName":"default"}}'

# Or recreate PVC without storageClassName requirement
```

### Cause 3: Label Selector Mismatch
```bash
# Check PVC selector
kubectl get pvc <pvc-name> -o yaml | grep -A 5 "selector:"

# Example:
# selector:
#   matchLabels:
#     type: backup

# Check PV labels
kubectl get pv <pv-name> --show-labels

# If no matching labels, add them:
kubectl label pv <pv-name> type=backup

# Or recreate PVC without selector
```

### Cause 4: Insufficient Capacity
```bash
# Check PV capacity
kubectl get pv <pv-name> -o jsonpath='{.spec.capacity.storage}'
# Output: 1Gi

# Check PVC requested size
kubectl get pvc <pvc-name> -o jsonpath='{.spec.resources.requests.storage}'
# Output: 10Gi

# PV capacity less than PVC request - won't bind

# Fix: Create larger PV or recreate PVC with smaller size
# Example PV with more capacity:
spec:
  capacity:
    storage: 10Gi  # ← Matches PVC request
```

### Cause 5: PVC Bound to Different PV
```bash
# Check what PV PVC is bound to
kubectl get pvc <pvc-name> -o jsonpath='{.spec.volumeName}'

# If already bound, it won't accept another PV
# Check if binding is working:
kubectl describe pvc <pvc-name> | grep -A 5 "Events"

# If bound correctly, PV should show:
kubectl get pv <pv-name> -o jsonpath='{.spec.claimRef}'

# If stuck in Available but should be bound, delete and recreate PVC
```

## Recovery Process
```bash
# 1. Verify PV exists and is available
kubectl get pv <pv-name>

# 2. Verify PVC exists
kubectl get pvc -n <namespace> <pvc-name>

# 3. Check if they can match
kubectl get pv <pv-name> -o yaml
kubectl get pvc -n <namespace> <pvc-name> -o yaml

# 4. Compare: capacity, accessModes, storageClassName, selector
# Should match or PVC should have no constraints

# 5. If no match, either:
#    - Delete PVC and recreate without constraints
#    - Create new PV matching PVC requirements
#    - Patch PV to match PVC

# 6. Monitor binding
watch 'kubectl get pv,pvc -A'
```

---

## PersistentVolumeClaim Issue: Stuck in Pending

**Symptoms:**
- PVC status is `Pending` indefinitely
- No PV binding despite available PVs
- Pod using PVC stuck in Pending

## Quick Diagnosis
```bash
# Check PVC status
kubectl get pvc -A

# Detailed PVC info
kubectl describe pvc <pvc-name> -n <namespace>

# Check for error events
kubectl describe pvc <pvc-name> -n <namespace> | grep -A 10 "Events"

# Common event: "no persistent volumes available"
# or "no storage class found"

# Check available PVs
kubectl get pv
```

## Common Causes & Fixes

### Cause 1: No Storage Class and No Manual PVs
```bash
# Check if using storage class
kubectl get pvc <pvc-name> -o yaml | grep storageClassName

# If storageClassName set but class doesn't exist:
kubectl get sc <class-name>
# Error: NotFound

# Fix: Either create storage class:
kubectl create storageclass fast --provisioner=kubernetes.io/aws-ebs --parameters=type=gp2

# Or delete PVC and recreate without storage class (for manual PVs):
kubectl delete pvc <pvc-name> -n <namespace>

kubectl apply -f - <<EOF
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: my-pvc
  namespace: <namespace>
spec:
  accessModes:
    - ReadWriteOnce
  # storageClassName: ""  # Remove this
  resources:
    requests:
      storage: 10Gi
EOF
```

### Cause 2: Storage Provisioner Failing
```bash
# Check if provisioner pod is running
kubectl get pods -n kube-system | grep provisioner

# If provisioner failing, check logs
kubectl logs -n kube-system <provisioner-pod>

# Common issue: AWS/GCP credentials not set

# If using AWS:
# Check AWS access key
kubectl get secret -n kube-system aws-secret

# If missing, create it:
kubectl create secret generic aws-secret \
  -n kube-system \
  --from-literal=aws_access_key_id=<key> \
  --from-literal=aws_secret_access_key=<secret>

# Restart provisioner pod
kubectl delete pod -n kube-system <provisioner-pod>
```

### Cause 3: Namespace Doesn't Exist
```bash
# Check if namespace exists
kubectl get ns <namespace>

# If not, create it:
kubectl create namespace <namespace>

# Then recreate PVC in namespace
```

### Cause 4: Pod Blocking Volume Binding
```bash
# PVC might be pending because pod needs it but can't schedule

# Check pod status
kubectl get pod -n <namespace>

# If pod is Pending, check why:
kubectl describe pod <pod-name> -n <namespace>

# Fix pod issue first, then PVC may auto-bind

# Or create PVC separately without pod first:
kubectl apply -f pvc.yaml
# Wait for binding, then create pod
```

## Recovery Process
```bash
# 1. Check PVC details
kubectl describe pvc <pvc-name> -n <namespace>

# 2. Note the error event (likely "no persistent volumes available")

# 3. Check available resources:
#    - PVs if using static provisioning
#    - StorageClass if using dynamic provisioning
#    - Provisioner pod if using provisioner

# 4. Apply fix based on cause above

# 5. Monitor binding
watch 'kubectl get pvc <pvc-name> -n <namespace>'
# Should show Bound status within seconds to minutes
```

---

## Dynamic Provisioning Issue: Storage Class Failing

**Symptoms:**
- PVC stuck in Pending
- StorageClass exists but PV not created
- Provisioner logs show errors

## Diagnosis
```bash
# Check storage class
kubectl get sc

# Check if default storage class set
kubectl get sc -o jsonpath='{.items[?(@.metadata.annotations.storageclass\.kubernetes\.io/is-default-class=="true")].metadata.name}'

# Check PVC storage class reference
kubectl get pvc <pvc-name> -o jsonpath='{.spec.storageClassName}'

# Check provisioner status
kubectl get pods -n kube-system -l app=<provisioner-name>

# Check provisioner logs
kubectl logs -n kube-system <provisioner-pod> --tail=50
```

## Common Issues & Fixes

### Issue: Provisioner Pod Crashing
```bash
# Check status
kubectl get pods -n kube-system -l app=<provisioner>

# If CrashLoopBackOff:
kubectl describe pod -n kube-system <provisioner-pod>

# Check logs
kubectl logs -n kube-system <provisioner-pod>

# Common reasons: permissions, credentials, API errors

# If credentials issue:
kubectl create secret generic <secret-name> \
  -n kube-system \
  --from-literal=<key>=<value>

# Restart provisioner
kubectl delete pod -n kube-system <provisioner-pod>
```

### Issue: Storage Quota Exceeded
```bash
# Check if namespace has resource quota
kubectl get resourcequota -n <namespace>

# Check current usage
kubectl describe resourcequota -n <namespace>

# If storage request exceeds quota:
# Either increase quota:
kubectl set resources -n <namespace> resourcequota <quota-name> \
  --storage=100Gi

# Or decrease PVC size:
kubectl patch pvc <pvc-name> -n <namespace> \
  -p '{"spec":{"resources":{"requests":{"storage":"5Gi"}}}}'
```

### Issue: Backend Storage Full
```bash
# If using AWS EBS/GCP PD, check backend status
# For AWS: Check EBS volume availability
# For GCP: Check persistent disk quota

# If backend full, either:
# 1. Delete unused volumes
# 2. Request quota increase
# 3. Use different region/zone

# Check PVC creation logs:
kubectl logs -n kube-system <provisioner-pod> | grep <pvc-name>
```

---

## PVC to Pod: PVC Not Mounted to Pod

**Symptoms:**
- PVC bound but pod shows no volume mount
- Pod accessing PVC but data not visible
- Pod stuck mounting volume

## Diagnosis
```bash
# Check PVC status
kubectl get pvc <pvc-name> -n <namespace>
# Should show: Bound

# Check pod volume section
kubectl get pod <pod-name> -o yaml | grep -A 10 "volumes:"

# Check mount points
kubectl get pod <pod-name> -o yaml | grep -A 10 "volumeMounts:"

# Verify in running pod
kubectl exec -it <pod-name> -n <namespace> -- mount | grep <pvc-name>

# If not mounted, check pod events
kubectl describe pod <pod-name> -n <namespace> | grep -A 10 "Events"
```

## Common Causes & Fixes

### Cause 1: Pod YAML Missing Volume Reference
```bash
# Check pod spec volumes
kubectl get pod <pod-name> -o yaml | grep volumes

# If volumes section missing or incomplete:
# Edit pod (requires recreate if already running)

kubectl delete pod <pod-name> -n <namespace>

# Recreate with volumes:
apiVersion: v1
kind: Pod
metadata:
  name: my-pod
spec:
  containers:
  - name: app
    image: nginx
    volumeMounts:
    - name: data
      mountPath: /data
  volumes:
  - name: data
    persistentVolumeClaim:
      claimName: my-pvc
```

### Cause 2: MountPath Issue
```bash
# Check if mountPath exists in image
# If not, pod fails to mount

# Check pod init logs
kubectl describe pod <pod-name> -n <namespace>

# If "mkdir: cannot create directory":
# Use subPath or different mountPath

# Example fix:
volumeMounts:
- name: data
  mountPath: /data
  subPath: myapp
```

### Cause 3: Volume Mount Timeout
```bash
# Check if pod stuck in ContainerCreating
kubectl get pod <pod-name> -n <namespace>

# Check events
kubectl describe pod <pod-name> -n <namespace> | tail -20

# Common: "timeout waiting for device" or similar

# This often means PVC not actually bound
# Go back and check PVC status
kubectl get pvc <pvc-name> -n <namespace>

# If Pending, fix PVC binding first
```

## Recovery Process
```bash
# 1. Verify PVC is bound
kubectl get pvc <pvc-name> -n <namespace>

# 2. Check pod yaml includes volume
kubectl get pod <pod-name> -o yaml | grep -A 3 volumes

# 3. Check pod yaml includes volumeMount
kubectl get pod <pod-name> -o yaml | grep -A 3 volumeMounts

# 4. Verify names match between volume and volumeMount

# 5. Check pod events for mount errors
kubectl describe pod <pod-name> -n <namespace>

# 6. If stuck, delete and recreate pod with correct YAML
```

---

## Quick Reference: Storage Issues

| Issue | Status Check | Common Fix |
|-------|--------------|-----------|
| PV stuck Available | `kubectl get pv` | Fix access mode, capacity, or labels |
| PVC Pending | `kubectl get pvc` | Create PV or provision storage class |
| Storage class fails | `kubectl logs provisioner` | Fix credentials or increase quota |
| Pod can't mount | `kubectl describe pod` | Fix volume reference or PVC binding |
| PVC not bound | `kubectl get pvc` | Check selector, capacity, access mode |

---

## CKA Exam Tips

- **PV lifecycle**: Created by admin, PVC requests binding, pod uses
- **Access modes critical**: RWO vs RWX determines which nodes can use
- **Reclaim policy**: Delete (default) vs Retain determines post-use
- **Dynamic provisioning**: StorageClass automates PV creation
- **Volume binding modes**: Immediate (default) vs WaitForFirstConsumer
- **Storage class must exist**: For dynamic provisioning to work
- **PVC selector**: Advanced but important for filtering available PVs
- **Namespace matters**: PVC in namespace X can only use PVs in X

---

## See Also
- Pod troubleshooting (pod mounting issues)
- StatefulSet data persistence (for database workloads)
- ConfigMap and Secret mounting (similar to PVC)
- Storage section scenarios for architecture details
