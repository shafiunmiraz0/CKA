# Scenario: etcd snapshot & restore (backup/restore quick notes)

Note: etcd snapshot/restore is a control-plane operation; only perform these with proper access and care. This is a short reference for exam-style admin tasks.

Quick diagnostics
- Check etcd member health (on control plane): `etcdctl --endpoints=<endpoint> endpoint status`
- Inspect etcd logs on control plane nodes: `journalctl -u etcd -n 200`

Create a snapshot (example)
- On a control-plane node with etcdctl configured:

ETCDCTL_API=3 etcdctl snapshot save /tmp/snapshot.db --endpoints=https://127.0.0.1:2379 --cacert=/etc/kubernetes/pki/etcd/ca.crt --cert=/etc/kubernetes/pki/etcd/server.crt --key=/etc/kubernetes/pki/etcd/server.key

Restore (high-level steps)
1) Stop control-plane components and etcd service on the node to be restored.
2) Move existing data directory (`/var/lib/etcd`) out of the way.
3) Use `etcdctl snapshot restore /tmp/snapshot.db --data-dir=/var/lib/etcd` with appropriate TLS flags and initial cluster settings.
4) Reconfigure etcd/systemd and start the etcd service; verify members join and health is OK.

Caveats
- Restoring etcd can be destructive if done incorrectly. In multi-node clusters, coordinate member restore carefully and understand initial-cluster-token and member IDs.

Exam tip
- For the CKA, you may only need to demonstrate taking a snapshot or restore in a lab environment—practice the commands on a local control-plane VM before attempting in a test environment.
