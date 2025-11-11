# StorageClass Scenario

## Scenario
Create a StorageClass and use it to provision dynamic PersistentVolumes via PVCs.

## Requirements
1. Create a StorageClass (example uses a generic provisioner placeholder).
2. Create a PVC that uses the StorageClass.
3. Verify the PV is dynamically provisioned and bound.

## YAML templates
### StorageClass (example)
```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: fast
provisioner: kubernetes.io/no-provisioner # replace with your CSI provisioner, e.g. ebs.csi.aws.com
volumeBindingMode: Immediate
reclaimPolicy: Delete
parameters:
  type: gp2
```

### PVC using StorageClass
```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: data-pvc
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 5Gi
  storageClassName: fast
```

## Commands
```bash
kubectl apply -f storageclass.yaml
kubectl apply -f pvc.yaml
kubectl get pvc
kubectl get pv
kubectl describe pvc data-pvc
```

## Verification
- `kubectl get pvc` should show `STATUS=Bound`.
- `kubectl get pv` will show a dynamically created PV with the StorageClass `fast`.

## Notes
- Replace the `provisioner` with your cluster's CSI driver.
- On local kind clusters you may need a hostPath provisioner or use `volume.beta.kubernetes.io/storage-provisioner: kubernetes.io/host-path` alternatives.
