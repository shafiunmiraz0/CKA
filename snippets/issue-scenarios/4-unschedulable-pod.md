# Scenario: Pod is unschedulable (Pending with events)

Symptom
- Pod remains Pending and `kubectl describe pod` shows events like "0/3 nodes are available: 3 Insufficient memory" or "node(s) had taint that the pod didn't tolerate".

Quick diagnostics
- kubectl describe pod <pod> -n <ns>   # read events
- kubectl get nodes -o wide
- kubectl describe node <node>         # check allocatable resources and taints

Common causes & fixes

1) Resource requests too high

Fix: reduce requests or add nodes / increase node size. Patch the deployment to lower requests.

Example patch (reduce memory request):

kubectl patch deploy myapp -n myns --type='json' -p='[{"op":"replace","path":"/spec/template/spec/containers/0/resources/requests/memory","value":"128Mi"}]'

2) Node taints without tolerations

Diagnosis: `kubectl describe node` shows taint like `node-role.kubernetes.io/control-plane:NoSchedule`.

Fix: add toleration to pod spec or remove taint if appropriate.

Example toleration YAML snippet:

```yaml
spec:
  template:
    spec:
      tolerations:
      - key: "node-role.kubernetes.io/control-plane"
        operator: "Exists"
        effect: "NoSchedule"
```

3) Node selectors or affinity preventing scheduling

If the pod requests nodeSelector or affinity that no node matches, update the pod spec.

4) Insufficient CPU / memory across cluster

Use `kubectl top nodes` (metrics-server) to check utilization. Add capacity or scale down other workloads.
