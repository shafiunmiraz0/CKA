# PersistentVolume + PersistentVolumeClaim Scenario

## Scenario
Create a static PersistentVolume (hostPath example) and bind it to a PersistentVolumeClaim.

## YAML templates
### Static PersistentVolume (hostPath)
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

### PVC that binds to the PV
```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: pv-claim
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 5Gi
  storageClassName: manual
```

## Commands
```bash
kubectl apply -f pv-hostpath.yaml
kubectl apply -f pvc.yaml
kubectl get pv
kubectl get pvc
kubectl describe pv pv-hostpath
kubectl describe pvc pv-claim
```

## Verification
- `kubectl get pv` should show `STATUS=Bound` for `pv-hostpath`.
- The PVC should also show `STATUS=Bound`.

## Notes
- Ensure the host path directory exists on the node where pods will be scheduled.
- For multi-node clusters hostPath is node-local; prefer NFS or other shared solutions for portability.
