# CKA — Study Materials & Exam Preparation

CKA Commands and YAML Templates Sheet for Kubernetes v1.30+

<!-- Place the PNG `Periodic Table of Kubernetes Commands.png` into the `images/` folder. -->
![Periodic Table of Kubernetes Commands](Periodic%20Table%20of%20Kubernetes%20Commands.png)

The image is handy during study; you can also keep the PNG in a GitHub repo open in the exam-allowed GitHub tab.

---

## 🚀 **EXAM-TIME QUICK LINKS** (Open these first during exam!)

**Start here on exam day:**
1. **[EXAM_QUICK_START.md](./EXAM_QUICK_START.md)** ← Strategy, time management, problem categories
2. **[QUICK_COMMANDS_ALL_DOMAINS.md](./QUICK_COMMANDS_ALL_DOMAINS.md)** ← Command cheat sheet (Ctrl+F to search)
3. **[EXAM_MEMORIZATION_CHECKLIST.md](./EXAM_MEMORIZATION_CHECKLIST.md)** ← Last-minute review (20 must-know commands)
4. **[Troubleshooting/issue-scenarios/](./Troubleshooting/issue-scenarios/)** ← Diagnostic playbooks (25+ scenarios)

**Keep these two browser tabs open during exam:**
- Tab 1: `https://kubernetes.io` (official docs)
- Tab 2: Your GitHub repo (above 4 files bookmarked)

---

## 📚 **How to Use This Repository**

### Before Exam (Study Phase)
- Read through domain-specific README files in each folder
- Work through scenario examples in `Troubleshooting/issue-scenarios/`
- Practice with YAML snippets from `cka-quick-templates.md`
- Do 1-2 full practice exams (2 hours each, timed)

### During Exam (2 Hours, 17 Problems)
- **First 5 min:** Read ALL problems, mark difficulty (easy/medium/hard)
- **Next 90 min:** Solve easy + medium problems (10-12 problems)
- **Final 25 min:** Attempt hard problems or review

### Problem-Solving Approach
1. Identify domain (Cluster, Workload, Network, Storage, Security, or Troubleshooting)
2. Open matching folder README or find scenario in `Troubleshooting/issue-scenarios/`
3. Copy command/YAML template from this repo
4. Customize for your specific problem
5. Apply (`kubectl apply -f`) and verify
6. Move to next problem

---

## 📂 **Repository Folder Guide**

### Exam Domains (with % of exam)

| Domain | % | Quick Start | Deep Dive |
|--------|---|-----------|-----------|
| **Cluster Architecture, Installation & Config** | 25% | `./Cluster.../README.md` | `./Cluster.../scenarios/` |
| **Workloads & Scheduling** | 15% | `./Workloads.../README.md` | `./Workloads.../scenarios/` |
| **Services & Networking** | 20% | `./Services.../README.md` | `./Services.../scenarios/` |
| **Storage** | 10% | `./Storage/README.md` | `./Storage/scenarios/` |
| **Security** | 5-10% | RBAC snippets | `Troubleshooting/` |
| **Troubleshooting** | 30% | `./Troubleshooting/README.md` | `./Troubleshooting/issue-scenarios/` |

### Quick File Reference

```
├── EXAM_QUICK_START.md                  ← Exam strategy & problem categories
├── EXAM_MEMORIZATION_CHECKLIST.md       ← Top 50 commands + YAML patterns
├── QUICK_COMMANDS_ALL_DOMAINS.md        ← Command reference (searchable)
├── DOMAIN_QUICK_SUMMARIES.md            ← 1-page per domain (coming soon)
├── CKA-commands-cheatsheet.md           ← Full cheat sheet
├── cka-quick-templates.md               ← Copy/paste YAML templates
│
├── Cluster.../README.md                 ← kubeadm, node mgmt, certs
├── Workloads.../README.md               ← Deployments, Pods, scaling
├── Services.../README.md                ← Services, Ingress, Networking
├── Storage/README.md                    ← PV, PVC, StorageClass
├── Troubleshooting/README.md            ← Debug commands
├── Troubleshooting/issue-scenarios/     ← 25+ real scenarios (start here!)
│
└── snippets-README.md                   ← Full YAML snippet index
```

---

## ⚡ **Top 20 Commands You MUST Memorize**

If you memorize these 20, you'll score 60%+:

1. `kubectl apply -f <file>`
2. `kubectl get <resource> -A`
3. `kubectl describe <resource> <name>`
4. `kubectl logs <pod>`
5. `kubectl exec -it <pod> -- /bin/sh`
6. `kubectl scale deployment/<name> --replicas=5`
7. `kubectl set image deployment/<name> container=image:tag`
8. `kubectl rollout undo deployment/<name>`
9. `kubectl rollout status deployment/<name>`
10. `kubectl expose deployment/<name> --port=80`
11. `kubectl get pvc -n <ns>`
12. `kubectl create role <name> --verb=get --resource=pods`
13. `kubectl auth can-i <verb> <resource>`
14. `kubectl cordon <node>`
15. `kubectl drain <node> --ignore-daemonsets --delete-local-data`
16. `kubeadm init --pod-network-cidr=10.244.0.0/16`
17. `kubeadm token create --print-join-command`
18. `kubectl get events --sort-by=.metadata.creationTimestamp`
19. `kubectl delete pod <pod> --grace-period=0 --force`
20. `kubectl port-forward svc/<name> 8080:80`

**See `EXAM_MEMORIZATION_CHECKLIST.md` for full list with examples.**

---

## 🔥 **Troubleshooting Quick Diagnostic Sequence**

When a problem says "something is broken, fix it":

```bash
# Step 1: Overview
kubectl get all -n <ns>

# Step 2: Detailed status (usually shows the problem!)
kubectl describe pod/<pod> -n <ns>

# Step 3: Logs
kubectl logs <pod> -n <ns> [--previous]

# Step 4: Recent events
kubectl get events -n <ns> --sort-by=.metadata.creationTimestamp

# Step 5: Execute into pod
kubectl exec -it <pod> -n <ns> -- /bin/sh

# Step 6: Check node (if scheduling issue)
kubectl describe node <node>
```

**This sequence solves 80% of troubleshooting problems!**

---

## Snippets — Quick index & exam toolbox

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
