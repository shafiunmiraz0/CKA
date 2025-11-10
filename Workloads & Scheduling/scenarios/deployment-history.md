# Deployment History & Revisions

## Purpose
Explain how Deployment revisions are recorded and how to inspect history for safe rollbacks in exam tasks.

## Commands
```bash
# Show rollout history
kubectl rollout history deployment/<name>

# Show details for a specific revision
kubectl rollout history deployment/<name> --revision=<n>

# Show current ReplicaSets (revisions are stored as ReplicaSets)
kubectl get rs -l app=<label>

# Inspect ReplicaSet annotations for revision info
kubectl get rs <rs-name> -o yaml | grep -i revision -A 3
```

## How revisions are created
- Each rollout creates a new ReplicaSet. The ReplicaSet gets an annotation `deployment.kubernetes.io/revision`.
- `revisionHistoryLimit` controls how many old ReplicaSets are retained.

## Example workflow
1. Deploy initial version (revision 1).
2. Update image (revision 2).
3. Inspect history: `kubectl rollout history deployment/myapp`.
4. If undesired: `kubectl rollout undo deployment/myapp --to-revision=1`.

## Troubleshooting & notes
- If `kubectl rollout history` shows only one revision, `revisionHistoryLimit` may be set to 0 or ReplicaSets cleaned up.
- To retain history, set `revisionHistoryLimit: N` in deployment spec.
- Use `kubectl get rs -o wide` to map ReplicaSet names to pods and ages.

## Exam tips
- Before rolling back, confirm target revision exists via `kubectl rollout history`.
- Quickly view ReplicaSets and their revisions with `kubectl get rs -o custom-columns=NAME:.metadata.name,REVISION:.metadata.annotations.deployment\.kubernetes\.io/revision`.
