# Scenario: Service exists but pods are not reachable

Symptom
- Service `myservice` responds with no endpoints or connection refused from clients.

Quick diagnostics
- kubectl get svc -n <ns>
- kubectl describe svc <svc> -n <ns>    # check selector
- kubectl get endpoints <svc> -n <ns>
- kubectl get pods -l <selector> -n <ns>

Common causes & fixes

1) Service selector doesn't match pod labels

Diagnosis: `kubectl describe svc` shows selector, `kubectl get pods -l` returns nothing.

Fix: Either change pod labels or update the Service selector.

Example: patch service selector

kubectl patch svc myservice -n myns -p '{"spec":{"selector":{"app":"myapp"}}}'

Or label the pods:

kubectl label pod <pod-name> -n myns app=myapp --overwrite

2) Target pods are in a different namespace

Remember Services are namespace-scoped. Confirm pods are in the same namespace.

3) Pod readiness probe failing -> endpoints empty

Check `kubectl get pods` and `kubectl describe pod` for readiness probe failures. Fix or temporarily remove readiness probe for debugging.

Example: remove readiness probe quickly (patch)

kubectl patch deploy myapp -n myns --type='json' -p='[{"op":"remove","path":"/spec/template/spec/containers/0/readinessProbe"}]'

4) NodePort / firewall / kube-proxy issue (for cluster access)

Check `kubectl get nodes`, `kubectl get ds -n kube-system` for kube-proxy, and `iptables` rules on nodes if you have node access.

Quick endpoint verification on a node

kubectl get pods -o wide -n myns
kubectl exec -it <pod> -n myns -- curl -sS http://myservice:80/ || true
