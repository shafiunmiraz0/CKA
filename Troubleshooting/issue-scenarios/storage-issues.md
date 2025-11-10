# Storage Troubleshooting Scenarios

## Common Storage Issues

### 1. PV/PVC Binding Issues
**Symptoms:**
- PVC stuck in Pending state
- Pod stuck in ContainerCreating state
- Volume mount failures

**Debugging Steps:**
```bash
# Check PVC status
kubectl get pvc
kubectl describe pvc <pvc-name>

# Check available PVs
kubectl get pv
kubectl describe pv <pv-name>

# Check pod events
kubectl describe pod <pod-name>
```

**Example PV/PVC:**
```yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: example-pv
spec:
  capacity:
    storage: 1Gi
  accessModes:
    - ReadWriteOnce
  hostPath:
    path: /tmp/data
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: example-pvc
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 1Gi
```

### 2. StorageClass Issues
**Symptoms:**
- Dynamic provisioning not working
- Storage class not found
- Provisioner errors

**Debugging Steps:**
```bash
# Check storage classes
kubectl get storageclass
kubectl describe storageclass <storageclass-name>

# Check provisioner pods
kubectl get pods -n kube-system | grep provisioner

# Check events
kubectl get events | grep PersistentVolume
```

**Example StorageClass:**
```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: standard
provisioner: kubernetes.io/aws-ebs
parameters:
  type: gp2
reclaimPolicy: Delete
allowVolumeExpansion: true
```

### 3. Volume Mount Problems
**Symptoms:**
- Container can't access volume
- Permission denied errors
- Wrong mount path

**Debugging Steps:**
```bash
# Check pod volume mounts
kubectl describe pod <pod-name> | grep -A 2 Mounts

# Check container filesystem
kubectl exec -it <pod-name> -- df -h
kubectl exec -it <pod-name> -- ls -la <mount-path>

# Check mount propagation
kubectl get pod <pod-name> -o yaml | grep mountPropagation
```

**Example Pod with Volume:**
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: volume-debug
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
      claimName: example-pvc
```

### 4. Volume Expansion Issues
**Symptoms:**
- PVC expansion fails
- Volume size not increasing
- Filesystem not resized

**Debugging Steps:**
```bash
# Check PVC capacity
kubectl get pvc <pvc-name>
kubectl describe pvc <pvc-name>

# Check storage class
kubectl get storageclass <storageclass-name> -o yaml | grep allowVolumeExpansion

# Check pod filesystem
kubectl exec -it <pod-name> -- df -h
```

## Quick Reference Commands

```bash
# Get storage resources
kubectl get pv,pvc
kubectl get sc

# Check volume details
kubectl describe pv <pv-name>
kubectl describe pvc <pvc-name>

# Check pod volume mounts
kubectl describe pod <pod-name> | grep -A 5 Volumes

# Delete stuck PVC
kubectl patch pvc <pvc-name> -p '{"metadata":{"finalizers":null}}'
kubectl delete pvc <pvc-name>

# Force delete PV
kubectl patch pv <pv-name> -p '{"metadata":{"finalizers":null}}'
kubectl delete pv <pv-name> --force --grace-period=0
```

## Common Storage Configurations

### 1. Dynamic Provisioning
```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: fast
provisioner: kubernetes.io/gce-pd
parameters:
  type: pd-ssd
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: fast-pvc
spec:
  storageClassName: fast
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 5Gi
```

### 2. Static Provisioning
```yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: static-pv
spec:
  capacity:
    storage: 10Gi
  accessModes:
    - ReadWriteOnce
  hostPath:
    path: /mnt/data
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: static-pvc
spec:
  volumeName: static-pv
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 10Gi
```