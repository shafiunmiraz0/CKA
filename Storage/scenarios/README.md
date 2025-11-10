# Storage (10%)# Storage (10%)## Storage — Commands & YAML



This folder contains commands, YAML templates and scenario walkthroughs for Storage topics relevant to the CKA exam.



Scenarios includedThis folder contains commands, YAML templates and scenario walkthroughs for Storage topics relevant to the CKA exam.PersistentVolume (PV), PersistentVolumeClaim (PVC), StorageClass examples and commands.

- Storage Class: `scenarios/storage-class/README.md`

- Shared Volume (RWX): `scenarios/shared-volume/README.md`

- PVC Resize: `scenarios/pvc-resize/README.md`

- StorageClass + PV + PVC + Pod (end-to-end): `scenarios/sc-pv-pvc-pod/README.md`Topics included (each has a scenario README with commands and YAML templates):Common commands

- Static PV + PVC: `scenarios/pv-pvc/README.md`

- PVC + Pod example: `scenarios/pvc-pod/README.md`- Storage Class (`scenarios/storage-class/README.md`)- List PVs and PVCs:

- PVC basics and troubleshooting: `scenarios/pvc/README.md`

- PV basics: `scenarios/pv/README.md`- Shared Volume (`scenarios/shared-volume/README.md`)	```bash



Quick commands- PersistentVolumeClaim Resize (`scenarios/pvc-resize/README.md`)	kubectl get pv



```powershell- StorageClass + PV + PVC + Pod (`scenarios/sc-pv-pvc-pod/README.md`)	kubectl get pvc -A

# List storage classes

kubectl get storageclass- PersistentVolume + PersistentVolumeClaim (`scenarios/pv-pvc/README.md`)	```



# List PVs and PVCs- PersistentVolumeClaim + Pod (`scenarios/pvc-pod/README.md`)- Describe a PV or PVC:

kubectl get pv

kubectl get pvc -A- PersistentVolumeClaim (`scenarios/pvc/README.md`)	```bash



# Describe PV/PVC- PersistentVolume (`scenarios/pv/README.md`)	kubectl describe pv <pv-name>

kubectl describe pv <pv-name>

kubectl describe pvc <pvc-name> -n <ns>	kubectl describe pvc <pvc-name> -n <ns>



# Patch PVC to request more storage (if supported)Quick commands	```

kubectl patch pvc <pvc-name> -n <ns> -p '{"spec":{"resources":{"requests":{"storage":"10Gi"}}}}'



# Restart pod using PVC if filesystem doesn't auto-resize

kubectl delete pod <pod-using-pvc> -n <ns>```bashDynamic provisioning (PVC) example

```# Storage (10%)



YAML snippets (examples)This folder contains commands, YAML templates and scenario walkthroughs for Storage topics relevant to the CKA exam. Each scenario README includes step-by-step commands, verification steps and minimal YAML templates.



- `scenarios/storage-class/storageclass.yaml` — StorageClass exampleScenarios included

- `scenarios/pv-pvc/pv-hostpath.yaml` — static hostPath PV example (lab use only)- Storage Class: `scenarios/storage-class/README.md`

- `scenarios/pvc/pvc.yaml` — PVC example- Shared Volume (RWX): `scenarios/shared-volume/README.md`

- PVC Resize: `scenarios/pvc-resize/README.md`

Notes- StorageClass + PV + PVC + Pod (end-to-end): `scenarios/sc-pv-pvc-pod/README.md`

- Static PV + PVC: `scenarios/pv-pvc/README.md`

- On managed cloud clusters, use cloud provider StorageClasses (EBS, PD, Azure Disk). For labs, hostPath or local provisioners may be used.- PVC + Pod example: `scenarios/pvc-pod/README.md`

- Not all provisioners support volume expansion — check `allowVolumeExpansion` and provisioner docs.- PVC basics and troubleshooting: `scenarios/pvc/README.md`

- RWX (ReadWriteMany) requires a CSI driver or NFS-type provisioner.- PV basics: `scenarios/pv/README.md`



SnippetsQuick commands



- `../snippets/pvc.yaml` (PersistentVolumeClaim)```powershell

- `../snippets/pv-hostpath.yaml` (hostPath PersistentVolume)# List storage classes

- `../snippets/storageclass.yaml` (StorageClass example)kubectl get storageclass



CKA tips# List PVs and PVCs

kubectl get pv

- If a PVC stays `Pending`, run `kubectl describe pvc <pvc>` and check events for provisioning failures.kubectl get pvc -A

- For static PVs ensure `storageClassName`, accessModes and size match the PVC.

- Practice creating PV/PVC/POD flows and resizing PVCs in a lab cluster.# Describe PV/PVC

kubectl describe pv <pv-name>

See the `scenarios/` directory for detailed walkthroughs and YAML examples.kubectl describe pvc <pvc-name> -n <ns>


# Patch PVC to request more storage (if supported)
kubectl patch pvc <pvc-name> -n <ns> -p '{"spec":{"resources":{"requests":{"storage":"10Gi"}}}}'

# Restart pod using PVC if filesystem doesn't auto-resize
kubectl delete pod <pod-using-pvc> -n <ns>
```

YAML snippets (examples)

- `scenarios/storage-class/storageclass.yaml` — StorageClass example
- `scenarios/pv-pvc/pv-hostpath.yaml` — static hostPath PV example (lab use only)
- `scenarios/pvc/pvc.yaml` — PVC example

Notes

- On managed cloud clusters, use cloud provider StorageClasses (EBS, PD, Azure Disk). For labs, hostPath or local provisioners may be used.
- Not all provisioners support volume expansion — check `allowVolumeExpansion` and provisioner docs.
- RWX (ReadWriteMany) requires a CSI driver or NFS-type provisioner.

Snippets

- `../snippets/pvc.yaml` (PersistentVolumeClaim)
- `../snippets/pv-hostpath.yaml` (hostPath PersistentVolume)
- `../snippets/storageclass.yaml` (StorageClass example)

CKA tips

- If a PVC stays `Pending`, run `kubectl describe pvc <pvc>` and check events for provisioning failures.
- For static PVs ensure `storageClassName`, accessModes and size match the PVC.
- Practice creating PV/PVC/POD flows and resizing PVCs in a lab cluster.

See the `scenarios/` directory for detailed walkthroughs and YAML examples.
- On managed cloud clusters, use cloud storage classes (AWS EBS, GCE PD, Azure Disk). For the exam/lab, hostPath and a simple storageclass may be acceptable for tests.

