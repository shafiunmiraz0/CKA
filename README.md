# CKA
CKA Commands and YAML Templates Sheet

<!-- Place the PNG `Periodic Table of Kubernetes Commands.png` into the `images/` folder. -->
![Periodic Table of Kubernetes Commands](Periodic%20Table%20of%20Kubernetes%20Commands.png)

The image is handy during study; you can also keep the PNG in a GitHub repo open in the exam-allowed GitHub tab.

# Snippets — Quick index & exam toolbox

This decorated README is optimized for quick browsing during practice or the exam.

## How this page is organized
- Quick commands (one-liners to run immediately)
- Most-used snippets (top picks)
- Organized categories with direct file links
- Troubleshooting scenarios (short playbooks)
- A small helper script to quickly copy a snippet to your clipboard (`tools\open-snippet.ps1`)

---

## Quick commands (paste these)
- kubectl get all -n <ns>
- kubectl describe pod <pod> -n <ns>
- kubectl logs <pod> -c <container> -n <ns> --previous
- kubectl get events -A --sort-by=.metadata.creationTimestamp
- kubectl top nodes
- kubectl auth can-i <verb> <resource> -n <ns>
- kubectl apply -f <file>
- kubectl patch deploy <name> -n <ns> --type='json' -p '[{"op":"replace","path":"/spec/template/spec/containers/0/image","value":"myimage:tag"}]'

## Most-used snippets (open first)
- `cka-quick-templates.md` — compact templates & small cheats
- `issue-scenarios/` — step-by-step troubleshooting playbooks
- `cluster-maintenance-commands.md` — common admin ops

## Workloads
- `deployment.yaml` — Deployment with labels
- `daemonset.yaml` — DaemonSet example
- `statefulset.yaml` — StatefulSet with PVCs
- `job.yaml` / `cronjob.yaml` — Job & CronJob examples

## Networking
- `service-clusterip.yaml` — ClusterIP
- `service-nodeport.yaml` — NodePort
- `ingress-basic.yaml` — Ingress (simple)
- `ingress-tls.yaml` — Ingress w/ TLS
- `networkpolicy-allow-dns.yaml` — allow DNS egress

## Storage
- `pvc.yaml` — PVC
- `pv-hostpath.yaml` — hostPath PV (lab)
- `storageclass.yaml` — StorageClass example
- `secret-tls.yaml` — TLS secret example

## Security
- `rbac-role-sa.yaml` — Role/RoleBinding/ServiceAccount
- `rbac-clusterrolebinding.yaml` — ClusterRole + binding
- `podsecurity-namespace-labels.yaml` — PSA labels

## Observability
- `metrics-server.yaml` — metrics-server for `kubectl top`
- `prometheus-basic.yaml` — minimal Prometheus
- `fluentbit-daemonset.yaml` — logging DaemonSet



## Troubleshooting scenarios (start here)
Open the `Troubleshooting/` folder. High-value items:
See the [Admin Setup Guide](./Troubleshooting/issue-scenarios/README.md) for more details.


- Keep this README and `cka-quick-templates.md` open in your allowed GitHub tab; they contain the fastest copy/paste manifests.

---

Good luck — keep this as your quick reference during practice and the exam.
