# Cluster maintenance & common admin commands (CKA / 1.34)

This file lists common cluster maintenance and admin commands you should memorise for CKA/CKS style tasks.

Node lifecycle
- Cordon (mark unschedulable):
  kubectl cordon <node>
- Drain (evict pods safely before maintenance):
  kubectl drain <node> --ignore-daemonsets --delete-local-data --force
- Uncordon (make schedulable):
  kubectl uncordon <node>

Certificates / kubeadm
- List kubeadm certs: `kubeadm certs check-expiration`
- Renew all certificates: `kubeadm certs renew all`

Cluster debugging and introspection
- Dump cluster state (control-plane logs, events):
  kubectl cluster-info dump --output-directory=./cluster-dump
- List api-resources and versions:
  kubectl api-resources
  kubectl api-versions

Resource & performance
- Show resource usage (requires metrics-server):
  kubectl top nodes
  kubectl top pods -n <ns>

Workloads / scheduling
- Force delete a stuck pod:
  kubectl delete pod <pod> --grace-period=0 --force -n <ns>
- Evict for PDB-safe eviction (if supported):
  kubectl evict pod <pod> -n <ns>

Ephemeral containers (debugging)
- Inject an ephemeral container for debugging (kubectl >=1.18+):
  kubectl debug -it pod/<pod> --image=busybox --target=<container>

Auth checks
- Check whether an identity can perform an action:
  kubectl auth can-i create deployment -n <ns>

Notes
- Keep these commands on your allowed GitHub tab for quick reference during the exam.
