# Scenario: Ingress returns 502/503 or backend unavailable

Symptom
- Ingress controller returns 502/503 errors for paths that route to Services that appear healthy.

Quick diagnostics
- kubectl describe ingress <ingress> -n <ns>
- kubectl get svc -n <ns>
- kubectl get endpoints <svc> -n <ns>
- kubectl get pods -l <selector> -n <ns>
- kubectl logs -n <ingress-namespace> <ingress-controller-pod>

Common causes & fixes

1) Service has no endpoints (pods not ready)

Fix: check readiness probes on pods; fix app or readiness probe, or temporarily remove probe to allow traffic during debugging.

2) Service port mismatch or targetPort incorrect

Fix: verify service `spec.ports.targetPort` matches container port.

3) Ingress controller misconfiguration or backend protocol mismatch (http vs https)

Fix: review controller annotations and backend protocol settings; test service directly with `kubectl port-forward` or `curl` from a pod.

Quick test from a pod
- kubectl run -i --tty curlpod --image=radial/busyboxplus:curl --restart=Never -- sh
- inside: curl -v http://<svc>.<ns>.svc.cluster.local:<port>/
