# StorageClass — Scenarios & Commands

## Overview
A **StorageClass** is a Kubernetes resource that describes how to provision a PersistentVolume. It acts as a template for dynamic provisioning, allowing PVCs to automatically trigger PV creation through a provisioner.

---

## Scenario 1: Create a Basic StorageClass

**Task**: Create a StorageClass for dynamic provisioning.

### YAML
```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: standard
provisioner: kubernetes.io/no-provisioner  # In labs; use real provisioner in production
reclaimPolicy: Delete
volumeBindingMode: Immediate
```

### Commands
```bash
# Create StorageClass
kubectl apply -f storageclass.yaml

# List all StorageClasses
kubectl get storageclass
kubectl get sc  # Shorthand

# Get StorageClass details
kubectl describe sc standard
kubectl describe storageclass standard

# Get StorageClass in YAML
kubectl get sc standard -o yaml

# Check if it's default
kubectl get sc standard -o json | grep isDefaultStorageClass
```

### Verification
```bash
# StorageClass should appear in list
kubectl get sc

# Should show provisioner and reclaim policy
kubectl describe sc standard
```

### Key Concepts
- **Provisioner**: Component that creates PVs (e.g., `kubernetes.io/host-path`, `ebs.csi.aws.com`)
- **Reclaim Policy**: What happens to PV when PVC is deleted (Delete/Retain)
- **Volume Binding Mode**: When PV is provisioned (Immediate/WaitForFirstConsumer)

---

## Scenario 2: Cloud-Provider StorageClasses

**Task**: Use cloud provider-specific StorageClasses.

### AWS EBS StorageClass
```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: ebs-gp2
provisioner: ebs.csi.aws.com
parameters:
  type: gp2          # General Purpose SSD
  iops: "100"
  throughput: "125"
reclaimPolicy: Delete
allowVolumeExpansion: true
volumeBindingMode: WaitForFirstConsumer
```

### GCE PD StorageClass
```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: pd-ssd
provisioner: kubernetes.io/gce-pd
parameters:
  type: pd-ssd       # SSD Persistent Disk
  fstype: ext4
reclaimPolicy: Delete
```

### Azure Disk StorageClass
```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: managed-premium
provisioner: kubernetes.io/azure-disk
parameters:
  kind: Managed
  storageaccounttype: Premium_LRS
reclaimPolicy: Delete
```

### Commands
```bash
# List all StorageClasses in cluster
kubectl get sc

# On AWS EKS cluster:
kubectl get sc | grep ebs

# On GKE cluster:
kubectl get sc | grep gce-pd

# On Azure AKS cluster:
kubectl get sc | grep azure

# Check if any StorageClass is default (marked with *)
kubectl get sc
# Output will show * next to default class

# Describe cloud-specific parameters
kubectl describe sc ebs-gp2
```

---

## Scenario 3: Default StorageClass

**Task**: Set a default StorageClass for the cluster.

### YAML
```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: default-sc
  annotations:
    storageclass.kubernetes.io/is-default-class: "true"  # Mark as default
provisioner: ebs.csi.aws.com
reclaimPolicy: Delete
```

### Commands
```bash
# Check which StorageClass is default (marked with *)
kubectl get sc

# Set StorageClass as default via patch
kubectl patch storageclass <name> -p '{"metadata": {"annotations": {"storageclass.kubernetes.io/is-default-class":"true"}}}'

# Remove default designation
kubectl patch storageclass <name> -p '{"metadata": {"annotations": {"storageclass.kubernetes.io/is-default-class":"false"}}}'

# Create PVC without storageClassName (will use default)
kubectl apply -f pvc-no-class.yaml  # If no storageClassName specified, uses default

# Verify default class is used
kubectl describe pvc <name>
```

### YAML for PVC Using Default Class
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
  # storageClassName omitted - will use default
```

---

## Scenario 4: StorageClass with Parameters

**Task**: Create StorageClass with provisioner-specific parameters.

### YAML with Parameters
```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: fast-ssd
provisioner: ebs.csi.aws.com
parameters:
  type: gp3                    # Storage type
  iops: "3000"                # IOPS (I/O operations/sec)
  throughput: "125"           # Throughput MB/s
  kms_key_id: "arn:aws:..."  # KMS encryption key
reclaimPolicy: Delete
allowVolumeExpansion: true
volumeBindingMode: Immediate
```

### Common Parameters by Provisioner

#### AWS EBS
```yaml
parameters:
  type: gp2|gp3|io1|sc1|st1
  iops: "1000"
  throughput: "125"
  kms_key_id: <ARN>
```

#### GCE PD
```yaml
parameters:
  type: pd-standard|pd-ssd
  fstype: ext4|ext3
```

#### NFS
```yaml
parameters:
  nfsvers: "4.1"
  nolock: "true"
```

### Commands
```bash
# Create StorageClass with parameters
kubectl apply -f sc-with-params.yaml

# Verify parameters
kubectl describe sc fast-ssd

# Check parameters in YAML
kubectl get sc fast-ssd -o yaml | grep -A 10 parameters

# PVC using this class will inherit parameters
kubectl apply -f pvc-using-params.yaml
```

---

## Scenario 5: Volume Binding Modes

**Task**: Understand and use different volume binding modes.

### Immediate Binding Mode
```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: immediate-sc
provisioner: ebs.csi.aws.com
volumeBindingMode: Immediate  # PV created immediately when PVC created
reclaimPolicy: Delete
```

### WaitForFirstConsumer Binding Mode
```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: wait-sc
provisioner: ebs.csi.aws.com
volumeBindingMode: WaitForFirstConsumer  # PV created only when pod scheduled
reclaimPolicy: Delete
```

### Comparison
```
Immediate:
- PV provisioned immediately when PVC created
- Faster but may not be on optimal node
- Default behavior

WaitForFirstConsumer:
- Waits for pod to be scheduled
- Provisions PV on pod's node (topology-aware)
- Better for multi-zone clusters
- Requires topology labels on nodes
```

### Commands
```bash
# Create StorageClass with WaitForFirstConsumer
kubectl apply -f sc-wait.yaml

# Create PVC
kubectl apply -f pvc.yaml

# PVC will be Pending (waiting for consumer)
kubectl get pvc

# Create pod that uses PVC
kubectl apply -f pod.yaml

# Now PV will be provisioned on the pod's node
kubectl get pvc
kubectl get pv
```

---

## Scenario 6: Reclaim Policies

**Task**: Understand PV reclaim policies set by StorageClass.

### Delete Policy (Default for Cloud)
```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: delete-sc
provisioner: ebs.csi.aws.com
reclaimPolicy: Delete  # PV and underlying storage deleted when PVC deleted
```

### Retain Policy
```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: retain-sc
provisioner: ebs.csi.aws.com
reclaimPolicy: Retain  # PV kept after PVC deletion, data preserved
```

### Behavior Comparison
```
Delete:
- PVC deleted → PV deleted → Cloud resource deleted
- Fast cleanup but data lost
- Default for cloud provisioners

Retain:
- PVC deleted → PV remains in Released state → Manual cleanup needed
- Data preserved until explicitly deleted
- Good for important data
```

### Commands
```bash
# Check reclaim policy
kubectl describe sc delete-sc

# Change reclaim policy (not directly on PVC, but via PV patch)
# First identify PV
kubectl get pvc app-pvc -o jsonpath='{.spec.volumeName}'

# Patch PV reclaim policy
kubectl patch pv <pv-name> -p '{"spec":{"persistentVolumeReclaimPolicy":"Retain"}}'

# Verify
kubectl describe pv <pv-name> | grep -i reclaim
```

---

## Scenario 7: Allow Volume Expansion

**Task**: Enable PVC resizing in StorageClass.

### YAML with Expansion Support
```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: expandable
provisioner: ebs.csi.aws.com
reclaimPolicy: Delete
allowVolumeExpansion: true  # Enables PVC size increase
```

### Commands
```bash
# Check if StorageClass supports expansion
kubectl describe sc expandable | grep -i "allow"

# Create PVC with expandable class
kubectl apply -f pvc-expandable.yaml

# Get initial size
kubectl get pvc app-pvc

# Resize PVC
kubectl patch pvc app-pvc -p '{"spec":{"resources":{"requests":{"storage":"20Gi"}}}}'

# Monitor resize
kubectl describe pvc app-pvc

# Check in pod
kubectl exec -it <pod-name> -- df -h /data
```

### Resize Limitations
```
- Can only increase size, not decrease
- Not all provisioners support expansion
- Some filesystems require offline expansion
- CSI drivers vary in expansion support
```

---

## Scenario 8: Provisioner Options

**Task**: Compare different provisioners and their use cases.

### Built-in Kubernetes Provisioners
```yaml
---
# Local HostPath (labs only)
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: hostpath
provisioner: kubernetes.io/host-path

---
# No Provisioner (static PVs only)
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: manual
provisioner: kubernetes.io/no-provisioner
```

### Cloud Provisioners
```yaml
---
# AWS EBS (CSI)
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: ebs
provisioner: ebs.csi.aws.com

---
# GCE PD
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: gce-pd
provisioner: kubernetes.io/gce-pd

---
# Azure Disk
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: azure-disk
provisioner: kubernetes.io/azure-disk
```

### CSI Provisioners
```yaml
---
# NFS CSI
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: nfs
provisioner: nfs.csi.k8s.io

---
# iSCSI
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: iscsi
provisioner: iscsi.csi.dobs.com
```

### Commands
```bash
# List all StorageClasses and their provisioners
kubectl get sc -o wide

# Check provisioner details
kubectl get sc <name> -o yaml | grep provisioner

# List CSI drivers installed
kubectl get csidrivers

# Check if provisioner pod is running
kubectl get pods -n kube-system | grep csi
```

---

## Scenario 9: Troubleshooting StorageClass Issues

### Issue 1: StorageClass Not Found

```bash
# Error: "no PersistentVolume with binding mode WaitForFirstConsumer found"

# Check if StorageClass exists
kubectl get sc <name>

# If not found, create it
kubectl apply -f storageclass.yaml

# Verify it appears in list
kubectl get sc
```

### Issue 2: Provisioner Not Running

```bash
# PVC stuck in Pending
kubectl describe pvc app-pvc

# Check if provisioner pod is running
kubectl get pods -n kube-system | grep provisioner

# Check provisioner logs
kubectl logs -n kube-system <provisioner-pod>

# If not running, install CSI driver
# Example for EBS CSI:
helm repo add aws-ebs-csi-driver https://kubernetes-sigs.github.io/aws-ebs-csi-driver
helm install aws-ebs-csi-driver aws-ebs-csi-driver/aws-ebs-csi-driver -n kube-system
```

### Issue 3: Provisioning Failed

```bash
# Check events
kubectl describe pvc app-pvc | tail -20

# Look for detailed error message
kubectl get events --sort-by='.lastTimestamp' | tail -5

# Common causes:
# - Provisioner quota exceeded
# - Storage backend unavailable
# - Insufficient permissions
# - Invalid parameters
```

### Issue 4: Default StorageClass Not Set

```bash
# Check if any class is marked as default
kubectl get sc

# If not, mark one as default
kubectl patch storageclass <name> -p '{"metadata": {"annotations": {"storageclass.kubernetes.io/is-default-class":"true"}}}'

# Verify
kubectl get sc  # Should show * next to default
```

---

## Scenario 10: StorageClass Listing and Management

**Task**: Effectively list, inspect, and manage StorageClasses.

### Common Commands
```bash
# List all StorageClasses
kubectl get storageclass
kubectl get sc  # Shorthand

# List with additional columns
kubectl get sc -o wide

# List sorted by provisioner
kubectl get sc --sort-by=.provisioner

# Get StorageClass in YAML
kubectl get sc <name> -o yaml

# Get StorageClass in JSON
kubectl get sc <name> -o json

# Describe StorageClass (detailed)
kubectl describe sc <name>

# Watch StorageClass changes
kubectl get sc --watch

# Get custom columns
kubectl get sc -o custom-columns=NAME:.metadata.name,PROVISIONER:.provisioner,DEFAULT:.metadata.annotations."storageclass\.kubernetes\.io/is-default-class"

# Delete StorageClass
kubectl delete sc <name>

# Edit StorageClass
kubectl edit sc <name>
```

### Output Interpretation
```
NAME                          PROVISIONER             RECLAIMPOLICY   VOLUMEBINDINGMODE   ALLOWVOLUMEEXPANSION   AGE
standard (default)            ebs.csi.aws.com         Delete          Immediate           true                   10d
slow                          kubernetes.io/gce-pd    Retain          WaitForFirstConsumer false                  5d
local                         kubernetes.io/host-path Delete          Immediate           false                  2d
```

### Bulk Operations
```bash
# Delete all StorageClasses except default
kubectl delete sc --all --selector="storageclass.kubernetes.io/is-default-class!=true"

# List all StorageClasses used by PVCs
kubectl get pvc -A -o jsonpath='{.items[*].spec.storageClassName}' | tr ' ' '\n' | sort -u

# Get StorageClass usage statistics
kubectl get pvc -A -o json | jq '[.items[].spec.storageClassName] | group_by(.) | map({class: .[0], count: length})'
```

---

## CKA Exam Tips

- **StorageClass is the key**: Know it controls provisioning, policies, and parameters
- **Default class matters**: PVCs without storageClassName use default if set
- **Binding modes**: `Immediate` vs `WaitForFirstConsumer` affects node locality
- **Reclaim policies**: `Delete` for cloud, `Retain` for important data
- **Expansion support**: Not automatic; StorageClass must have `allowVolumeExpansion: true`
- **Provisioner knowledge**: Understand what provisioner is available in the test cluster
- **Quick diagnosis**: `kubectl get sc` and `kubectl describe pvc` are your friends
- **Lab provisioners**: Typically hostPath or no-provisioner; know how to work with static PVs

---

## Quick Reference

| Task | Command |
|------|---------|
| List StorageClasses | `kubectl get sc` |
| Check default class | `kubectl get sc` (look for *) |
| Describe StorageClass | `kubectl describe sc <name>` |
| Create StorageClass | `kubectl apply -f sc.yaml` |
| Delete StorageClass | `kubectl delete sc <name>` |
| Set as default | `kubectl patch storageclass <name> -p '{"metadata": {"annotations": {"storageclass.kubernetes.io/is-default-class":"true"}}}'` |
| Get YAML | `kubectl get sc <name> -o yaml` |
| Check provisioner | `kubectl get sc <name> -o jsonpath='{.provisioner}'` |
| List CSI drivers | `kubectl get csidrivers` |

---

## See Also
- [Storage Classes - Kubernetes Docs](https://kubernetes.io/docs/concepts/storage/storage-classes/)
- `scenarios/storage-class/` — Detailed scenario walkthroughs
- `scenarios-pvc.md` — PersistentVolumeClaim scenarios
- `storage/storageclass.yaml` — StorageClass example
