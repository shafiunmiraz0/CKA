# Shared Volume Scenario

## Scenario
Configure a shared volume (ReadWriteMany) where multiple pods can mount the same volume.

## Requirements
1. Provide a StorageClass and CSI driver that supports ReadWriteMany (e.g., NFS, GlusterFS, or specific cloud drivers).
2. Create a PVC with accessMode ReadWriteMany.
3. Mount the PVC into two separate pods and verify write/read.

## YAML templates
### PVC with ReadWriteMany
```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: shared-pvc
spec:
  accessModes:
    - ReadWriteMany
  resources:
    requests:
      storage: 2Gi
  storageClassName: nfs
```

### Pod A
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: writer-pod
spec:
  containers:
  - name: writer
    image: busybox
    command: ["/bin/sh","-c","echo hello > /data/hello.txt; sleep 3600"]
    volumeMounts:
    - mountPath: /data
      name: shared
  volumes:
  - name: shared
    persistentVolumeClaim:
      claimName: shared-pvc
```

### Pod B
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: reader-pod
spec:
  containers:
  - name: reader
    image: busybox
    command: ["/bin/sh","-c","sleep 3600"]
    volumeMounts:
    - mountPath: /data
      name: shared
  volumes:
  - name: shared
    persistentVolumeClaim:
      claimName: shared-pvc
```

## Commands
```bash
kubectl apply -f pvc-nfs.yaml
kubectl apply -f writer-pod.yaml
kubectl apply -f reader-pod.yaml
kubectl exec -it reader-pod -- cat /data/hello.txt
```

## Verification
Reader pod should output `hello` from the shared file.

## Notes
- Many cloud default provisioners only support ReadWriteOnce; for RWX use NFS or specialized CSI drivers.
- For the exam, know how to create PVs for hostPath/NFS if cluster CSI isn't available.
