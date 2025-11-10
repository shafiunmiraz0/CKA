## Storage — Commands & YAML

PersistentVolume (PV), PersistentVolumeClaim (PVC), StorageClass examples and commands.

Common commands
- List PVs and PVCs:
	```bash
	kubectl get pv
	kubectl get pvc -A
	```
- Describe a PV or PVC:
	```bash
	kubectl describe pv <pv-name>
	kubectl describe pvc <pvc-name> -n <ns>
	```

Dynamic provisioning (PVC) example
```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
	name: mypvc
spec:
	accessModes:
		- ReadWriteOnce
	resources:
		requests:
			storage: 1Gi
	storageClassName: standard
```

Static hostPath PV example (lab use only)
```yaml
apiVersion: v1
kind: PersistentVolume
metadata:
	name: pv-hostpath
spec:
	capacity:
		storage: 1Gi
	accessModes:
		- ReadWriteOnce
	hostPath:
		path: /mnt/data
```

StorageClass (example)
```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
	name: standard
provisioner: kubernetes.io/no-provisioner # for local PV example; cloud provisioners differ
volumeBindingMode: Immediate
```

Notes
- On managed cloud clusters, use cloud storage classes (AWS EBS, GCE PD, Azure Disk). For the exam/lab, hostPath and a simple storageclass may be acceptable for tests.

Snippets
- Storage-related snippets are in `../snippets/` (relative to this README):
	- `../snippets/pvc.yaml` (PersistentVolumeClaim)
	- `../snippets/pv-hostpath.yaml` (hostPath PersistentVolume)
	- `../snippets/storageclass.yaml` (StorageClass example)
		- `../snippets/snippets-README.md` (index of all snippets)

