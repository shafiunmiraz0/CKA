# PersistentVolume (PV) Scenario

## Scenario
Create and manage PersistentVolumes (static PV example using hostPath) and understand reclaim policies.

## YAML templates
### Static PV (hostPath)
```yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: pv-example
spec:
  capacity:
    storage: 2Gi
  accessModes:
    - ReadWriteOnce
  persistentVolumeReclaimPolicy: Retain
  storageClassName: manual
  hostPath:
    path: /mnt/data/pv-example
```

## Commands
```bash
kubectl apply -f pv.yaml
kubectl get pv
kubectl describe pv pv-example
kubectl delete pv pv-example
```

## Reclaim policies
- Retain: keeps volume after PVC deletion (manual cleanup)
- Recycle: legacy, not recommended
- Delete: deletes the underlying resource when PV reclaimed (common for dynamic PVs)

## Notes
- Ensure host directories exist on nodes for hostPath PVs.
- For multi-node clusters, hostPath PVs are node-local; prefer NFS for portable PVs.
