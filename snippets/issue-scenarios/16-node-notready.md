# Scenario: Node NotReady / Node condition issues

Symptom
- Node shows `NotReady` in `kubectl get nodes` and pods scheduled on the node may be `Unknown` or `Pending`.

Quick diagnostics
- kubectl get nodes -o wide
- kubectl describe node <node>
- kubectl -n kube-system get pods -o wide | grep kubelet
- On node: check `systemctl status kubelet` and `journalctl -u kubelet -n 200` (requires SSH/node access)

Common causes & fixes

1) Kubelet unable to report Ready status (network/CNI issues, disk pressure)

Fix: fix underlying node issue (CNI, out-of-disk, kernel) and restart kubelet.

2) Node network partitioned from control plane

Fix: check node routing and kubelet flags (apiserver endpoint). If the node is unrecoverable in exam time, cordon and drain and recreate workloads on healthy nodes.

Quick remediation
- kubectl cordon <node>
- kubectl drain <node> --ignore-daemonsets --delete-local-data
