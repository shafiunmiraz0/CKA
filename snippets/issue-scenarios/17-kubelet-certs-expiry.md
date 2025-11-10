# Scenario: Kubelet certificate expiry / kubelet unable to register

Symptom
- Nodes go NotReady or kubelet can't register with the API; logs show TLS/certificate errors or "x509: certificate has expired or is not yet valid".

Quick diagnostics
- kubectl get nodes -o wide
- ssh to node and inspect kubelet logs: `sudo journalctl -u kubelet -n 200`
- check certificates on node: `/var/lib/kubelet/pki/kubelet.crt` and `/var/lib/kubelet/pki/kubelet.key` (requires node access)

Common causes & fixes

1) Kubelet client certificate expired

Fix: On control plane with kubeadm, rotate kubelet certificates or use `kubeadm certs renew` / `kubeadm alpha certs renew kubelet` depending on version. For managed nodes, follow provider instructions.

Example (kubeadm-managed clusters)

sudo kubeadm certs renew all
sudo systemctl restart kubelet

2) Node TLS bootstrap failed or CSR not approved

Diagnosis: `kubectl get csr` and look for pending CSRs from nodes.

Fix: Approve node CSR if appropriate:

kubectl get csr
kubectl certificate approve <csr-name>

3) Incorrect time / clock skew on node

Fix: ensure NTP/time sync on the node; TLS validation relies on correct time.

Exam tips
- If you can't access nodes directly, check `kubectl get nodes -o wide` and cluster events. If immediate remediation is required, drain the node and move workloads to healthy nodes: `kubectl cordon <node>` / `kubectl drain <node> --ignore-daemonsets --delete-local-data`.
