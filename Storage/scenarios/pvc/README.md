# PersistentVolumeClaim (PVC) Scenario

## Scenario
Demonstrate creating and inspecting PVCs, checking events when PVCs are Pending, and troubleshooting common issues.

## Commands
```bash
# Create a PVC from yaml
kubectl apply -f pvc.yaml

# Check status
kubectl get pvc
kubectl describe pvc <pvc-name>

# View events to see provisioning failures
kubectl get events --sort-by=.metadata.creationTimestamp

# Delete PVC
kubectl delete pvc <pvc-name>
```

## Troubleshooting PVC Pending
- Check `kubectl describe pvc <pvc>` for events explaining why it's Pending.
- Verify StorageClass exists and provisioner is available.
- For static PVs, ensure a PV with matching size, accessModes and storageClassName exists and is Available.
- Check CSI driver/controller logs if dynamic provisioning fails.

## YAML example
```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: my-pvc
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 2Gi
  storageClassName: standard
```
