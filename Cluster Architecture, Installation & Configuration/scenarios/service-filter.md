# Service Filter (Listing & Troubleshooting)

## Purpose
Commands and examples to filter and inspect Services, Endpoints, and related resources.

## List and Filter Services
```bash
# List all services in all namespaces
kubectl get svc --all-namespaces

# List services in a namespace
kubectl get svc -n default

# Filter by label
kubectl get svc -l app=web -n default

# Output wide or YAML
kubectl get svc -o wide
kubectl get svc myservice -o yaml
```

## Inspect Endpoints and Targets
```bash
# Get endpoints for a service
kubectl get endpoints myservice -o yaml

# Describe service to see endpoints
kubectl describe svc myservice

# Verify endpoints match pods
kubectl get endpoints myservice -o jsonpath='{.subsets[*].addresses[*].ip}'
kubectl get pods -o wide --selector=app=web
```

## Troubleshooting
- "No endpoints": check labels on pods and selectors in the service.
- Port mismatch: ensure `targetPort` corresponds to container port in pods.
- NodePort not reachable: check node firewall and kube-proxy logs.

## Useful commands
```bash
# Get services and their clusterIP/nodePort
kubectl get svc -o custom-columns=NAME:.metadata.name,TYPE:.spec.type,CLUSTER-IP:.spec.clusterIP,NODE-PORT:.spec.ports[*].nodePort

# Delete service
kubectl delete svc myservice
```
