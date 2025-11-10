# Create Pod (Quick Examples)

## Purpose
Fast patterns to create pods during the exam using YAML and `kubectl run`.

## Create pod with `kubectl run`
```bash
# Simple pod
kubectl run busybox --image=busybox --restart=Never -- sleep 3600

# Interactive pod for debugging
kubectl run -i --tty debug --image=busybox --restart=Never -- sh
```

## Create pod from YAML
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: my-pod
spec:
  containers:
  - name: app
    image: busybox
    command: ["/bin/sh","-c","sleep 3600"]
```

## Create pod with node selector and toleration
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: nodepod
spec:
  nodeSelector:
    disk: ssd
  tolerations:
  - key: "key"
    operator: "Equal"
    value: "value"
    effect: "NoSchedule"
  containers:
  - name: app
    image: nginx
```

## Common flags and shortcuts
```bash
# Show generated YAML for quick editing
kubectl run nginx --image=nginx --dry-run=client -o yaml > nginx-pod.yaml

# Create and immediately exec
kubectl run -i --tty debug --image=busybox --restart=Never -- sh
```

## Troubleshooting
- Pod stuck Pending: check `kubectl describe pod` for scheduling reasons
- Pod CrashLoopBackOff: check `kubectl logs --previous` and `kubectl describe pod`

## Exam tips
- Use `kubectl run` for fast one-off pods. Use `--restart=Never` to create Pod instead of Deployment.
- Use `--dry-run=client -o yaml` to generate manifest and tweak quickly.
