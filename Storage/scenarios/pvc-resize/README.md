# PVC Resize Scenario

## Scenario
Increase the size of a PersistentVolumeClaim and ensure the filesystem inside the pod grows accordingly.

## Requirements
1. The StorageClass must allow volume expansion (allowVolumeExpansion: true).
2. Update the PVC request to a larger size.
3. Verify PV/PVC reflect new size and pod can use the extra space.

## Steps and YAML
### Example StorageClass enabling expansion
```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: expandable
provisioner: kubernetes.io/no-provisioner # replace with real CSI
allowVolumeExpansion: true
reclaimPolicy: Retain
```

### Patch PVC to larger size
```bash
kubectl patch pvc data-pvc -n default -p '{"spec":{"resources":{"requests":{"storage":"10Gi"}}}}'
```

### Verify
```bash
kubectl get pvc data-pvc -o yaml
kubectl describe pvc data-pvc
kubectl get pv
```

## Filesystem resize inside the pod
- Many CSI drivers will automatically expand the underlying block device and the kubelet will trigger filesystem resize.
- If not automatic, you can `exec` into the pod and run filesystem tools (e.g., resize2fs for ext4) after unmounting or following driver-specific steps.

## Notes
- Not all provisioners support expansion; check `allowVolumeExpansion` and provisioner docs.
- Some filesystems (xfs) require offline expansion or special commands.
