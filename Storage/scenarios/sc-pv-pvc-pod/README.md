# StorageClass + PV + PVC + Pod Scenario

## Scenario
Demonstrate end-to-end provisioning: StorageClass -> PVC -> PV -> Pod using dynamically provisioned storage.

## YAML samples
### StorageClass (example)
```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: standard
provisioner: kubernetes.io/no-provisioner # replace with your CSI driver
reclaimPolicy: Delete
volumeBindingMode: Immediate
```

### PVC
```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: app-pvc
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 1Gi
  storageClassName: standard
```

### Pod that uses the PVC
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: app-pod
spec:
  containers:
  - name: app
    image: nginx
    volumeMounts:
    - mountPath: /usr/share/nginx/html
      name: app-storage
  volumes:
  - name: app-storage
    persistentVolumeClaim:
      claimName: app-pvc
```

## Commands
```bash
kubectl apply -f storageclass.yaml
kubectl apply -f pvc.yaml
kubectl apply -f pod.yaml
kubectl get pvc
kubectl get pv
kubectl describe pvc app-pvc
kubectl exec -it app-pod -- ls /usr/share/nginx/html
```

## Verification
- PVC should be Bound and PV created.
- Pod should mount the volume and be able to read/write files.

## Notes
- If dynamic provisioning isn't available, create a static PV and bind it to the PVC by matching `claimRef` and `storageClassName`.
