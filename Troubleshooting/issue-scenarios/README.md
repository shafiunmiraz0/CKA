# Issue scenarios (exam-style)

This folder contains concise, copy/paste-ready scenarios you may encounter on the CKA exam.
Each scenario includes: symptoms, quick diagnostic commands, and one or more fix examples (commands and YAML manifests).

Files in this folder:
- `1-pod-crashloop.md` — Pod CrashLoopBackOff diagnosis & fixes
- `2-service-not-reachable.md` — Service selector / endpoints troubleshooting
- `3-pvc-pending.md` — PVC bound/pending troubleshooting and PV example
- `4-unschedulable-pod.md` — Pod scheduling failures (taints, resources, affinity)
- `5-image-pull-error.md` — ImagePullBackOff and imagePullSecret usage
 - `6-rbac-access-denied.md` — RBAC "forbidden" / can-i troubleshooting and fixes
 - `7-podsecurity-admission.md` — PodSecurity admission denials and namespace labels
 - `8-ingress-tls-mismatch.md` — Ingress/TLS mismatch and secret troubleshooting
 - `9-kube-proxy-iptables.md` — kube-proxy / iptables connectivity troubleshooting
 - `10-evicted-pods.md` — Evicted pods due to node pressure (recreate/restore)
 - `11-coredns-issues.md` — CoreDNS failures and DNS resolution fixes
 - `12-hpa-no-metrics.md` — HPA/metrics-server diagnostics and fixes
 - `13-pvc-resize-stuck.md` — PVC resize pending and filesystem resize fixes
 - `14-ingress-503-backend.md` — Ingress returns 502/503 troubleshooting
 - `15-secret-mount-failure.md` — Secret/ConfigMap mount failures and fixes
 - `16-node-notready.md` — Node NotReady diagnostics and remediation
 - `17-kubelet-certs-expiry.md` — kubelet certificate expiry / CSR issues
 - `18-cronjob-not-running.md` — CronJob schedule/suspend issues and fixes
 - `19-missing-sa-token.md` — Missing ServiceAccount token or automount issues
 - `20-pod-stuck-terminating.md` — Pod stuck Terminating and finalizer / force-delete fixes
 - `21-admission-webhook-failures.md` — Mutating/Validating webhook rejections and workarounds
 - `22-api-server-high-latency.md` — API server 5xx/latency troubleshooting
 - `23-etcd-snapshot-restore.md` — etcd snapshot & restore notes (control-plane ops)
 - `24-pvc-terminating-finalizer.md` — PVC stuck Terminating due to finalizers
 - `25-pv-released-not-bound.md` — PV Released but not reclaimed / reclaimPolicy issues

Use these during practice to rehearse command sequences you can copy during the exam.
