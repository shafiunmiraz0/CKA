# Rollback Scenarios

## Purpose
Quick reference for using deployment rollbacks safely during the CKA exam.

## Commands
```bash
# Show rollout status
kubectl rollout status deployment/<name>

# Show rollout history
kubectl rollout history deployment/<name>

# Roll back to previous revision
kubectl rollout undo deployment/<name>

# Roll back to a specific revision
kubectl rollout undo deployment/<name> --to-revision=<revision>

# Pause/Resume rollout
kubectl rollout pause deployment/<name>
kubectl rollout resume deployment/<name>

# Force restart to trigger a rolling restart
kubectl rollout restart deployment/<name>
```

## YAML examples
```yaml
# Ensure revisionHistoryLimit is set to keep history for rollbacks
apiVersion: apps/v1
kind: Deployment
metadata:
  name: example-deploy
spec:
  replicas: 3
  revisionHistoryLimit: 5
  template:
    metadata:
      labels:
        app: example
    spec:
      containers:
      - name: app
        image: nginx:1.14
```

## Troubleshooting
- If `rollout undo` fails: check `kubectl rollout history` first to confirm revisions exist.
- If rollout is stuck: inspect `kubectl describe deployment <name>` and `kubectl get events`.
- Use `kubectl rollout undo --to-revision=<n>` when automatic rollback picks undesired revision.

## Exam tips
- Keep deployments with `revisionHistoryLimit` > 0 in the exam tasks where rollbacks are needed.
- Use `kubectl rollout status` to confirm rollback completion before moving on.
