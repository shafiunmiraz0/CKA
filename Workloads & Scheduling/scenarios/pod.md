# Pod Quick Reference (CKA)

## Create a Pod
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: quick-pod
spec:
  containers:
  - name: app
    image: nginx
    ports:
    - containerPort: 80
```

## Useful Commands
```bash
# Create from yaml
kubectl apply -f pod.yaml

# Get pods
kubectl get pods -o wide

# Describe pod
kubectl describe pod <name>

# Logs
kubectl logs <pod>
kubectl logs -c <container> <pod>

# Exec
kubectl exec -it <pod> -- /bin/sh

# Delete
kubectl delete pod <name>
```

## Probes
```yaml
livenessProbe:
  exec:
    command:
    - cat
    - /tmp/health
  initialDelaySeconds: 10
  periodSeconds: 5

readinessProbe:
  httpGet:
    path: /ready
    port: 8080
  initialDelaySeconds: 5
  periodSeconds: 5
```

## Resource requests/limits example
```yaml
resources:
  requests:
    memory: "64Mi"
    cpu: "250m"
  limits:
    memory: "128Mi"
    cpu: "500m"
```

## Scheduling examples
```yaml
# Node selector
nodeSelector:
  disk: ssd

# Tolerations
tolerations:
- key: "key"
  operator: "Equal"
  value: "value"
  effect: "NoSchedule"

# Affinity
affinity:
  nodeAffinity:
    requiredDuringSchedulingIgnoredDuringExecution:
      nodeSelectorTerms:
      - matchExpressions:
        - key: kubernetes.io/e2e-az-name
          operator: In
          values:
          - e2e-az1
```

## Troubleshooting
- Pending: check node selectors, taints, resource requests, and PVC binding.
- CrashLoopBackOff: use `kubectl logs --previous` and `kubectl describe pod`.
- ImagePullBackOff: verify image name, tag, and registry access; check imagePullSecrets.

## Exam tips
- Use `kubectl run` for quick pod creation during tasks.
- Keep small snippets ready for probes, resources, and scheduling changes.
