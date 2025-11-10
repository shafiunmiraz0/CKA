# Scenario: Pods are evicted (Evicted status)

Symptom
- Pod status is `Evicted`; `kubectl describe pod` shows "The node was low on resource: memory/cpu/disk" or "PodOOMKilled" events.

Quick diagnostics
- kubectl get pod -n <ns> --field-selector status.phase=Failed
- kubectl describe pod <pod> -n <ns>   # look for eviction events
- kubectl describe node <node>          # check Node conditions and Allocatable

Common causes & fixes

1) Node out-of-memory / disk pressure

Fix: drain the node and free resources, increase node capacity, or adjust resource requests/limits for pods.

Example: evicted pod recovery

kubectl delete pod <evicted-pod> -n <ns>
# re-create from Deployment/Job or apply saved manifest

2) Local ephemeral storage exhausted

Check node disk usage and clean /var/lib/kubelet or wallpapers from nodes (requires admin access).

Exam tip
- If pods are evicted and you need to get services running quickly, cordon/ drain bad node and scale replicas to other nodes: `kubectl cordon <node>` then `kubectl drain <node> --ignore-daemonsets --delete-local-data`.
