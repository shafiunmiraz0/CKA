# Pod + Service (Basic)

## Purpose
Simple Pod + ClusterIP Service example and common test commands for CKA tasks.

## YAML
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: nginx-pod
  labels:
    app: nginx
spec:
  containers:
  - name: nginx
    image: nginx:1.14
    ports:
    - containerPort: 80
---
apiVersion: v1
kind: Service
metadata:
  name: nginx-svc
spec:
  selector:
    app: nginx
  ports:
  - protocol: TCP
    port: 80
    targetPort: 80
  type: ClusterIP
```

## Commands
```bash
# Create resources
kubectl apply -f pod-svc.yaml

# Check pods and service
kubectl get pods -o wide
kubectl get svc nginx-svc
kubectl describe svc nginx-svc

# Test connectivity from another pod
kubectl run -it --rm busybox --image=busybox -- nslookup nginx-svc
kubectl run -it --rm busybox --image=busybox -- wget -qO- http://nginx-svc
```

## Troubleshooting
- Service has no endpoints: check labels match between Pod and Service.
- DNS resolution fails: check CoreDNS pods and `kubectl get configmap coredns -n kube-system`.
- Port mismatch: verify `targetPort` and container port alignment.

## Exam tips
- Use `kubectl describe svc` to quickly see endpoints and errors.
- Use a simple busybox pod to test service reachability during the exam.
