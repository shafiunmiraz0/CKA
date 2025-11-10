# Node Resource (Checks & Troubleshooting)

## Purpose
Commands for checking node-level resources, conditions, and resolving Node NotReady or resource pressure issues.

## Check nodes
```bash
# Basic node list
kubectl get nodes -o wide

# Describe a node for detailed conditions and allocations
kubectl describe node <node-name>
```

## Resource usage
```bash
# Requires metrics-server
kubectl top nodes
kubectl top node <node-name>

# Disk usage and inodes (on node)
df -h
df -i

# Check kubelet and container runtime status on node
systemctl status kubelet
journalctl -u kubelet -n 200
systemctl status containerd
```

## Node conditions and taints
```bash
# Show node conditions
kubectl get nodes -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.status.conditions[?(@.type=="Ready")].status}{"\n"}{end}'

# Show taints
kubectl get nodes -o custom-columns=NAME:.metadata.name,TAINTS:.spec.taints
```

## Troubleshooting
- Node NotReady: check kubelet logs, disk pressure, network connectivity.
- Kubelet crash or restart loops: inspect journalctl for kubelet and container runtime.
- Disk pressure: free up space or increase disk.

## Exam tips
- Use `kubectl describe node` to get quick visibility into why pods won't schedule.
- Know how to cordon/drain/uncordon nodes:
```bash
kubectl cordon <node>
kubectl drain <node> --ignore-daemonsets --delete-emptydir-data
kubectl uncordon <node>
```
