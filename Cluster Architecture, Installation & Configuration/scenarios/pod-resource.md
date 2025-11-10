# Pod Resource (Requests & Limits)

## Purpose
Reference and examples for configuring pod/container resource requests and limits and troubleshooting resource-related scheduling or OOM issues.

## YAML Examples
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: resource-demo
spec:
  containers:
  - name: app
    image: nginx
    resources:
      requests:
        cpu: "250m"
        memory: "128Mi"
      limits:
        cpu: "500m"
        memory: "256Mi"
```

## Check resource usage
```bash
# Requires metrics-server to be installed
kubectl top pods
kubectl top pod resource-demo
kubectl top nodes

# Describe pod to see requests/limits
kubectl describe pod resource-demo | grep -A 5 Requests
```

## Troubleshooting
- Pod stuck Pending: check if node has capacity to satisfy requests (`kubectl describe node`).
- OOMKilled: inspect `kubectl describe pod` and `kubectl logs`, increase memory limit or optimize application.
- CPU throttling: compare usage from `kubectl top` to requests/limits.

## Best practices
- Set requests for predictable scheduling.
- Use limits to protect node from noisy neighbors.
- Use QoS classes (Guaranteed / Burstable) appropriately.

## Exam tips
- Use `kubectl patch` to quickly change requests/limits during tasks.
- If time-constrained, use `kubectl set resources` to adjust containers in a deployment.
```bash
kubectl set resources deployment/myapp -c app --limits=cpu=500m,memory=256Mi --requests=cpu=250m,memory=128Mi
```