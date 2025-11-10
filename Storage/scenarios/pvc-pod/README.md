# PVC + Pod Scenario

## Scenario
Create a PVC and a Pod that consumes it, then verify read/write operations.

## YAML templates
### PVC
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
      storage: 1Gi
  storageClassName: standard
```

### Pod
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: app-using-pvc
spec:
  containers:
  - name: app
    image: busybox
    command: ["/bin/sh","-c","echo hello > /data/hello.txt; sleep 3600"]
    volumeMounts:
    - mountPath: /data
      name: data
  volumes:
  - name: data
    persistentVolumeClaim:
      claimName: data-pvc
```

## Commands
```bash
kubectl apply -f pvc.yaml
kubectl apply -f pod.yaml
kubectl exec -it app-using-pvc -- cat /data/hello.txt
```

## Verification
- The `cat` command inside the pod should show `hello`.

## Notes
- If PVC remains `Pending`, verify storage class, provisioner, and events: `kubectl describe pvc data-pvc`.
