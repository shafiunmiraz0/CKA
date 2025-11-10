# Pod Filter (Listing & Selection)

## Purpose
Commands and patterns to list and filter pods efficiently during CKA tasks.

## List and filter
```bash
# Get all pods
kubectl get pods --all-namespaces

# Filter by namespace
kubectl get pods -n kube-system

# Filter by label
kubectl get pods -l app=nginx

# Show wide output with node and IP
kubectl get pods -o wide

# Custom columns
kubectl get pods -o custom-columns=NAME:.metadata.name,STATUS:.status.phase,NODE:.spec.nodeName
```

## Field and JSONPath filtering
```bash
# Field selector example
kubectl get pods --field-selector=status.phase=Pending

# JSONPath example to get pod names
kubectl get pods -o jsonpath='{.items[*].metadata.name}'
```

## Grep and advanced filters
```bash
# Use grep to find pod events or names
kubectl get pods -o wide | grep CrashLoopBackOff

# Combine label and field selector
kubectl get pods -l app=web --field-selector=status.phase!=Running
```

## Troubleshooting
- If pods not listed: check namespace
- If label filters return none: verify labels with `kubectl get pods --show-labels`

## Exam tips
- Use `-o wide` and `-o custom-columns` to surface useful information quickly
- Combine `-l` and `--field-selector` to locate problematic pods fast
