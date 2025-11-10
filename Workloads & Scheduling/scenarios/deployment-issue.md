# Deployment — Common Issues & Troubleshooting

## Symptoms
- New pods not starting
- Deployment stuck "Progressing"
- Old ReplicaSet not terminating
- ImagePullBackOff or CrashLoopBackOff in new pods

## Debugging Steps
```bash
# Describe the deployment for events and conditions
kubectl describe deployment <name>

# Inspect replica sets
kubectl get rs -l app=<label>
kubectl describe rs <replicaset-name>

# List pods for the deployment
kubectl get pods -l app=<label> -o wide

# Describe failing pod
kubectl describe pod <pod-name>
kubectl logs <pod-name> [-c <container>]

# Check events
kubectl get events --sort-by=.metadata.creationTimestamp
```

## Common Causes & Fixes
- ImagePullBackOff: check image name, tag and registry access; confirm imagePullSecrets where required.
- CrashLoopBackOff: check `kubectl logs --previous` and container command/args; adjust probes or resource requests.
- Readiness probe failures: inspect probe paths and response codes; increase `initialDelaySeconds` during cold starts.
- Insufficient resources: check node capacity (`kubectl describe node`) and scheduling constraints (nodeSelector/affinity/taints).
- PodDisruptionBudget blocking updates: inspect PDBs and adjust `minAvailable` or timing.

## Remediation patterns
- Temporarily scale down new replica set, fix image/probes, then scale up.
- Use `kubectl rollout undo` if a bad update made the deployment unstable.
- Edit deployment to fix incorrect fields: `kubectl edit deployment/<name>`.

## Example quick checks
```bash
# Check for pods that failed to schedule
kubectl get pods -o wide | grep Pending

# Check for image pull errors
kubectl describe pod <pod-name> | grep -A 5 Events

# Force recreate the deployment (if acceptable)
kubectl delete pod -l app=<label> --grace-period=0 --force
```

## Exam tips
- Always check `kubectl describe deployment` first; it often shows the root cause.
- Use `kubectl rollout status` and `kubectl rollout history` when diagnosing rollouts.
- When time-limited, use selective `kubectl set image` to revert to a known-good image quickly.
