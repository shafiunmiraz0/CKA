# Scenario: PVC stays in Pending state

Symptom
- PersistentVolumeClaim remains in Pending and never binds.

Quick diagnostics
- kubectl get pvc -n <ns>
- kubectl describe pvc <pvc> -n <ns>    # shows events and StorageClass
- kubectl get pv
- kubectl get storageclass

Common causes & fixes

1) No matching StorageClass or dynamic provisioner

If the PVC specifies a StorageClass that doesn't exist or the cluster has no provisioner, PVC will stay pending.

Fix: Create a StorageClass with a provisioner your cluster supports (or remove storageClassName for default dynamic provisioning).

Example hostPath PV (lab-only) to satisfy a PVC quickly

```yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: pv-local-1
spec:
  capacity:
    storage: 5Gi
  accessModes:
    - ReadWriteOnce
  persistentVolumeReclaimPolicy: Retain
  storageClassName: manual
  hostPath:
    path: /mnt/data/pv-local-1

---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: pvc-claim-1
  namespace: myns
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: manual
  resources:
    requests:
      storage: 5Gi
```

Apply with:

kubectl apply -f pv-local-1.yaml

2) Mismatched access modes or insufficient capacity

Check PV accessModes and capacity. Create a PV meeting the requirements.
