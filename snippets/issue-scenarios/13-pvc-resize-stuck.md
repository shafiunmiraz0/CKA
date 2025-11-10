# Scenario: PVC resize remains Pending / filesystem not resized

Symptom
- You updated a PVC's storage request but `kubectl get pvc` still shows old size or the filesystem inside the pod isn't resized.

Quick diagnostics
- kubectl get pvc <pvc> -n <ns>
- kubectl describe pvc <pvc> -n <ns>
- kubectl get storageclass
- kubectl get pv

Common causes & fixes

1) StorageClass does not allow volume expansion

Fix: check `allowVolumeExpansion` on the StorageClass. If false, create a new StorageClass that allows expansion or provision a new PV.

2) Filesystem inside the volume wasn't expanded automatically

Fix: exec into the pod and run `df -h` and then resize the filesystem (`resize2fs` or xfs_growfs) depending on FS and tools available.

Example: patch StorageClass to allow expansion (if editable)

kubectl patch storageclass standard -p '{"metadata": {"annotations": {"patched":"true"}}, "allowVolumeExpansion": true }'

Example manual flow (lab): create new larger PV and migrate data or recreate PVC with the new size.
