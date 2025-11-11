# CKA Exam Quick Start Guide

**Last Updated:** November 2024  
**For CKA Exam:** Kubernetes v1.30+  
**Exam Duration:** 2 hours (17 problems, ~7 min per problem)

---

## ⏱️ Exam Strategy & Time Management

### Before Exam (Preparation)
- [ ] **Memorize** the essential kubectl commands (see `EXAM_MEMORIZATION_CHECKLIST.md`)
- [ ] **Practice** under timed conditions (full 2 hours)
- [ ] **Keep open** during exam:
  - Tab 1: `https://kubernetes.io` (official docs)
  - Tab 2: Your allowed GitHub repo with this folder's quick files

### During Exam (Time Allocation)
- **First 5 minutes (0:00-0:05):** Read ALL 17 problems. Mark difficulty: easy, medium, hard.
- **Next 90 minutes (0:05-1:35):** Solve all easy + medium problems (10-12 problems). Aim for ~6-7 min per problem.
- **Final 25 minutes (1:35-2:00):** Attempt hard problems. Don't get stuck on one problem.

### Scoring Breakdown (estimate)
- Solve 11/17 problems → ~70% pass score
- Solve 13/17 problems → ~85% high pass
- Solve 15/17 problems → ~95% excellent pass

**Action:** Prioritize speed + accuracy on medium problems. Hard problems are time-traps.

---

## 🗂️ Repository Structure at a Glance

Quick folder reference for exam-time lookup:

```
CKA/
├── README.md                              ← Main entry (open during exam)
├── EXAM_QUICK_START.md                    ← THIS FILE
├── EXAM_MEMORIZATION_CHECKLIST.md         ← Memorize these
├── QUICK_COMMANDS_ALL_DOMAINS.md          ← Command cheat sheet
├── DOMAIN_QUICK_SUMMARIES.md              ← 1-page summaries per domain
├── CKA-commands-cheatsheet.md             ← Full cheat sheet
├── cka-quick-templates.md                 ← Copy/paste YAML templates
│
├── Cluster Architecture, Installation & Configuration/  [25% of exam]
│   ├── README.md                          ← kubeadm init, join, resets
│   └── scenarios/                         ← Detailed walkthroughs
│
├── Workloads & Scheduling/                [15% of exam]
│   ├── README.md                          ← Deployment, DaemonSet, StatefulSet
│   └── scenarios/                         ← Deployment, Pod, scaling examples
│
├── Services & Networking/                 [20% of exam]
│   ├── README.md                          ← Service types, Ingress, NetworkPolicy
│   └── scenarios/                         ← Networking examples
│
├── Storage/                               [10% of exam]
│   ├── README.md                          ← PV, PVC, StorageClass
│   └── scenarios/                         ← Storage examples
│
├── Security/                              [? % of exam, typically 5-10%]
│   └── (RBAC examples in Cluster/ and snippets/)
│
├── Troubleshooting/                       [30% of exam]
│   ├── README.md                          ← Debugging commands
│   └── issue-scenarios/                   ← 25+ real scenarios (CrashLoop, PVC Pending, etc.)
│
├── Observability/                         [Cross-cutting concern]
│   └── Metrics, logging, debugging tools
│
└── snippets-README.md                     ← Full YAML snippet index
```

**Exam-time tip:** Bookmark `README.md`, `QUICK_COMMANDS_ALL_DOMAINS.md`, and the `Troubleshooting/issue-scenarios/` folder in your GitHub tab.

---

## 🔥 Critical Files to Keep Open During Exam

### Browser Tab 1: kubernetes.io (Official Docs)
- **Bookmark these for instant lookup:**
  - [Kubectl Reference](https://kubernetes.io/docs/reference/kubectl/)
  - [API Resources](https://kubernetes.io/docs/reference/generated/kubernetes-api/latest/)
  - [Resource Quotas](https://kubernetes.io/docs/concepts/policy/resource-quotas/)

### Browser Tab 2: Your GitHub Repo (This Folder)
**Most valuable files during exam:**
1. **`QUICK_COMMANDS_ALL_DOMAINS.md`** — 80% of questions answered here
2. **`cka-quick-templates.md`** — Copy/paste YAML for 90% of tasks
3. **`EXAM_MEMORIZATION_CHECKLIST.md`** — Last-minute quick review
4. **`Troubleshooting/issue-scenarios/`** — Diagnostic playbooks for debugging

---

## 🎯 Exam Problem Categories & Quick Response Map

### Category 1: Cluster Architecture (25%)
**Questions like:** "Initialize cluster", "Join worker", "Upgrade cluster", "Backup/restore"

**Quick response:**
- Open: `Cluster Architecture, Installation & Configuration/README.md`
- Commands: `kubeadm init`, `kubeadm join`, `kubeadm upgrade`, `kubeadm reset`
- Estimated time: 6-8 min per problem

**Must-memorize commands:**
```bash
kubeadm init --pod-network-cidr=10.244.0.0/16
kubeadm token create --print-join-command
kubeadm upgrade plan / apply
kubeadm reset -f
```

---

### Category 2: Workloads & Scheduling (15%)
**Questions like:** "Create Deployment", "Scale pods", "Update image", "Rollback", "Fix CrashLoopBackOff"

**Quick response:**
- Open: `Workloads & Scheduling/README.md` + `scenarios/deployment-*.md`
- Commands: `kubectl apply`, `kubectl rollout`, `kubectl scale`, `kubectl patch`
- Estimated time: 5-7 min per problem

**Must-memorize commands:**
```bash
kubectl apply -f deployment.yaml
kubectl rollout status deployment/name
kubectl rollout undo deployment/name
kubectl scale deployment/name --replicas=3
kubectl patch deploy name -p '{"spec":{"template":{"spec":{"containers":[{"name":"app","image":"new:tag"}]}}}}'
```

---

### Category 3: Services & Networking (20%)
**Questions like:** "Create Service", "Fix DNS", "Create Ingress", "NetworkPolicy"

**Quick response:**
- Open: `Services & Networking/README.md`
- Commands: `kubectl expose`, `kubectl port-forward`, `nslookup`, `curl`
- Estimated time: 6-8 min per problem

**Must-memorize commands:**
```bash
kubectl expose deployment/name --port=80 --target-port=8080 --type=ClusterIP
kubectl expose deployment/name --type=NodePort
kubectl port-forward svc/name 8080:80
nslookup service-name.namespace.svc.cluster.local
```

---

### Category 4: Storage (10%)
**Questions like:** "Create PVC", "Bind PV", "Dynamic provisioning", "Resize PVC"

**Quick response:**
- Open: `Storage/README.md` + `scenarios/scenarios-pvc.md`
- Commands: `kubectl get pv`, `kubectl get pvc`, `kubectl describe pvc`
- Estimated time: 5-7 min per problem

**Must-memorize commands:**
```bash
kubectl get pv
kubectl get pvc -A
kubectl describe pvc name
kubectl patch pvc name -p '{"spec":{"resources":{"requests":{"storage":"5Gi"}}}}'
```

---

### Category 5: Security (5-10%)
**Questions like:** "Create RBAC", "Pod security", "NetworkPolicy", "Secrets"

**Quick response:**
- Open: Snippets (RBAC, NetworkPolicy, Pod Security) + Cluster Architecture README
- Commands: `kubectl create role`, `kubectl auth can-i`, `kubectl apply -f networkpolicy.yaml`
- Estimated time: 6-8 min per problem

**Must-memorize commands:**
```bash
kubectl create role podreader --verb=get,list,watch --resource=pods
kubectl create rolebinding podreader-binding --clusterrole=podreader --serviceaccount=default:user
kubectl auth can-i get pods --as=system:serviceaccount:default:user
```

---

### Category 6: Troubleshooting (30%)
**Questions like:** "Why is pod in CrashLoopBackOff?", "Service not reachable", "PVC pending"

**Quick response:**
- Open: `Troubleshooting/README.md` + `Troubleshooting/issue-scenarios/` (pick matching scenario)
- Commands: `kubectl describe`, `kubectl logs`, `kubectl get events`, `kubectl exec`
- Estimated time: 7-10 min per problem (most complex)

**Must-memorize diagnostic sequence:**
```bash
1. kubectl get <resource> -A
2. kubectl describe <resource> <name>
3. kubectl logs <pod> [--previous]
4. kubectl get events --sort-by=.metadata.creationTimestamp
5. kubectl exec -it <pod> -- /bin/sh
```

---

## ⚡ Essential Commands to Memorize

### General
```bash
kubectl get all -n <ns>                  # Overview of namespace
kubectl get all -A                       # All resources, all namespaces
kubectl describe <resource> <name>       # Detailed troubleshooting
kubectl events -A --sort-by=...          # Track recent events
```

### Deployments & Workloads
```bash
kubectl create deployment name --image=image:tag
kubectl apply -f deployment.yaml
kubectl rollout status deployment/name
kubectl rollout undo deployment/name --to-revision=1
kubectl scale deployment/name --replicas=5
kubectl set image deployment/name container=image:tag
```

### Services & Networking
```bash
kubectl expose deployment/name --port=80 --target-port=8080
kubectl port-forward svc/name 8080:80
kubectl get svc -A
kubectl describe svc name
```

### Storage
```bash
kubectl get pv
kubectl get pvc -n <ns>
kubectl describe pvc name -n <ns>
kubectl patch pvc name -n <ns> -p '{"spec":{"resources":{"requests":{"storage":"10Gi"}}}}'
```

### Debugging
```bash
kubectl logs <pod> -n <ns>
kubectl logs <pod> -n <ns> --previous
kubectl exec -it <pod> -n <ns> -- /bin/sh
kubectl cp <pod>:/path/file ./local -n <ns>
kubectl debug pod/<pod> -it --image=busybox
```

### Admin/Cluster
```bash
kubeadm init --pod-network-cidr=10.244.0.0/16
kubeadm join <ip>:6443 --token <token> --discovery-token-ca-cert-hash sha256:<hash>
kubectl cordon <node>
kubectl drain <node> --ignore-daemonsets --delete-local-data
kubectl uncordon <node>
```

---

## 🧠 Quick Review Before Exam (5 Minutes)

Read through `EXAM_MEMORIZATION_CHECKLIST.md` once:
- [ ] Cluster Architecture commands (5 commands)
- [ ] Deployment commands (5 commands)
- [ ] Service commands (3 commands)
- [ ] Storage commands (3 commands)
- [ ] Troubleshooting sequence (5 steps)

---

## 💡 Pro Tips

### Speed Techniques
1. **Use `kubectl apply` instead of `create`** — idempotent, works with existing resources
2. **Use aliases in kubeconfig** — `kc` for `kubectl` (if allowed in your exam environment)
3. **Copy/paste YAML from this repo** — Every second counts; don't type from scratch
4. **Use `--dry-run=client -o yaml`** — Generate YAML without applying
5. **Use `kubectl patch` for small edits** — Faster than `kubectl edit`

### Problem-Solving Approach
1. **Read problem carefully** — Identify the resource type and the action needed
2. **Identify the domain** — Is it Workload, Network, Storage, or Troubleshooting?
3. **Find matching file** — Open the folder README or scenario file
4. **Copy template** — Don't start from scratch
5. **Customize & apply** — Replace placeholders and `kubectl apply -f`
6. **Verify** — `kubectl get` or `kubectl describe` to confirm

### Troubleshooting Approach
When a problem says "something is broken, fix it":
1. **Don't assume** — Always start with `kubectl describe <resource>`
2. **Check events** — `kubectl get events --sort-by=.metadata.creationTimestamp`
3. **Read logs** — `kubectl logs <pod> [--previous]`
4. **Match scenario** — Open `Troubleshooting/issue-scenarios/` and find closest match
5. **Apply fix** — Copy command/YAML from scenario file
6. **Verify fix** — Re-run `kubectl describe` or `kubectl get`

### Time-Saving Tips
- **Bookmark snippet files** in your GitHub tab for 0-second access
- **Skip optional details** — Focus on what the problem asks, not perfection
- **Mark unsure problems** — Come back in final 10 minutes if time permits
- **Avoid perfectionism** — "Good enough and submitted" beats "perfect but no submit"

---

## 📋 Pre-Exam Checklist (Day Before)

- [ ] Read through `EXAM_MEMORIZATION_CHECKLIST.md` 2-3 times
- [ ] Do 1 full practice exam (2 hours, timed)
- [ ] Practice speed copy/paste from snippet files
- [ ] Verify your GitHub repo is public and accessible
- [ ] Bookmark all 5 main files in your browser
- [ ] Review `Troubleshooting/issue-scenarios/` folder structure
- [ ] Get good sleep the night before

---

## 🔗 Quick Links During Exam

**When you open GitHub repo, keep these tabs bookmarked:**

1. **Root README.md** — Folder structure + quick commands
2. **QUICK_COMMANDS_ALL_DOMAINS.md** — Command reference (open this first)
3. **cka-quick-templates.md** — YAML templates (copy/paste)
4. **Troubleshooting/README.md** — Debug commands
5. **Troubleshooting/issue-scenarios/INDEX_AND_ORGANIZATION.md** — Scenario index

**When reading a problem:**
- Identify domain (Cluster, Workload, Network, Storage, or Troubleshooting)
- Open matching folder README or scenario file from bookmarks
- Copy command or YAML template
- Customize for your specific problem
- Apply and verify

---

## 🎬 Example Exam Problem Walkthrough

**Problem:** "The deployment 'web' in namespace 'app' has 5 replicas but only 2 pods are running. One pod is in CrashLoopBackOff. Fix the deployment."

**Solution steps:**

1. **Identify domain** → Troubleshooting (CrashLoopBackOff)
2. **Open file** → `Troubleshooting/issue-scenarios/1-pod-crashloop.md`
3. **Copy diagnostic sequence:**
   ```bash
   kubectl describe pod <pod-name> -n app
   kubectl logs <pod-name> -n app --previous
   kubectl get events -n app --sort-by=.metadata.creationTimestamp
   ```
4. **Find root cause** → From logs/events, identify issue (e.g., wrong image, missing env var)
5. **Apply fix** → Patch or edit deployment, replace image/env/command
6. **Verify** → `kubectl get pods -n app` → should show all running
7. **Move to next problem**

**Total time:** ~6-8 minutes for medium-difficulty problem

---

## ✅ Final Check Before Submitting Exam

1. **All problems attempted?** Yes → Submit
2. **Time remaining?** > 5 min → Do final review of easiest unsolved problems
3. **Time remaining?** < 5 min → Submit and done

**Remember:** 70% pass = Passing score. You don't need perfection.

---

## 📞 Questions During Exam?

- Contact exam proctor (usually Examslocal or PSI support)
- They can only help with technical issues, not problem understanding
- Expect 5-10 min response time for technical support

---

**Good luck! You've got this. 🚀**

See `EXAM_MEMORIZATION_CHECKLIST.md` for the critical stuff to memorize.

