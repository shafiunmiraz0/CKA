# Scenario: API server high latency / 5xx errors

Symptom
- `kubectl` commands are slow or return 500/504 errors; control plane components show errors in logs.

Quick diagnostics
- kubectl get --raw /healthz
- kubectl get --raw /metrics | head -n 40  # inspect apiserver metrics if accessible
- kubectl -n kube-system logs -l component=kube-apiserver  # check controller logs on control plane

Common causes & fixes

1) High request load (DDOS / heavy clients)

Fix: Identify noisy clients via apiserver request metrics, throttle or remove them. In exam, check recently created resources or automation.

2) Etcd problems causing slowness

Fix: Check etcd status on control plane: `kubectl -n kube-system logs -l component=etcd` and consider restoring from snapshot if etcd is unhealthy (see etcd snapshot scenario).

3) Resource exhaustion on control plane nodes (CPU, disk I/O)

Fix: Inspect node metrics and consider moving non-critical workloads off control plane, or restart components carefully.

Quick remediation for exam
- Retry the command after a short wait. Use `kubectl proxy` to reduce repeated auth overhead for many small `kubectl` calls.
