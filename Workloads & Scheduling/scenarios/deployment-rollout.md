# Deployment Rollout (pause/resume/history)

## Overview
Rollout management controls how a Deployment updates pods (pause, resume, history, undo).

## Common Commands
```bash
# Pause/Resume
kubectl rollout pause deployment/<name>
kubectl rollout resume deployment/<name>

# Check rollout status
kubectl rollout status deployment/<name>

# Get rollout history
kubectl rollout history deployment/<name>

# Get details of a revision
kubectl rollout history deployment/<name> --revision=<n>

# Undo rollout (rollback)
kubectl rollout undo deployment/<name>
```

## YAML notes
- Keep `revisionHistoryLimit` to a reasonable number (default 10) if rollbacks are expected.
- Use `readinessProbe` to ensure new pods are ready before proceeding.

## Example: Pause, make change, resume
```bash
# Pause
kubectl rollout pause deployment/myapp

# Update image or patch
kubectl set image deployment/myapp myapp=myimage:2.0

# Resume rollout
kubectl rollout resume deployment/myapp

# Monitor
kubectl rollout status deployment/myapp
```

## Troubleshooting
- If rollout hangs: `kubectl describe deployment <name>` to view conditions and events.
- If pods never become ready: inspect readiness/liveness probes and container logs.
- Use `kubectl rollout history` to decide revision to undo to.

## Exam tips
- Use pause/resume when you need to make multiple changes atomically.
- Always monitor `kubectl get pods -w` during a rollout to see real-time changes.
