# Scenario: HPA not scaling / metrics unavailable

Symptom
- HorizontalPodAutoscaler shows `unknown` or `metrics unavailable` and doesn't scale pods.

Quick diagnostics
- kubectl get hpa -n <ns>
- kubectl describe hpa <hpa> -n <ns>
- kubectl top pods -n <ns>
- kubectl get pods -n kube-system | grep metrics-server
- kubectl logs -n kube-system -l k8s-app=metrics-server

Common causes & fixes

1) metrics-server not installed or failing

Fix: install/fix metrics-server (see `../snippets/metrics-server.yaml`), ensure RBAC allows it to read metrics and that it can access kubelet APIs.

2) HPA configured for custom metrics which are missing

Fix: switch to resource metrics or install the appropriate metrics adapter.

Quick commands
- `kubectl apply -f ../snippets/metrics-server.yaml`
- `kubectl rollout restart deployment/metrics-server -n kube-system`
