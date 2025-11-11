# 🗺️ Troubleshooting Scenarios - Navigation Guide

## 📍 You Are Here: `/Troubleshooting/issue-scenarios/`

This folder contains **47 comprehensive Kubernetes troubleshooting scenario files** covering 60+ real-world failure modes organized by component and severity.

---

## 🚀 Getting Started in 60 Seconds

### What's in This Folder?
- ✅ 47 troubleshooting scenario files
- ✅ 60+ individual failure mode scenarios
- ✅ 600+ diagnostic and remediation commands
- ✅ 150+ YAML examples and templates
- ✅ 150+ CKA exam tips

### Quick Start:
1. **Problem?** → Look it up in [Quick Navigation by Error Message](#error-navigation)
2. **No specific error?** → Browse [Category Sections](#by-category)
3. **Preparing for CKA?** → Follow [Critical Path](#critical-path-study-guide)
4. **Incident response?** → Jump to relevant scenario file

---

## 📂 Quick File Categories

### 🔴 Critical (First Priority - Highest Failure Rate)
```
1-pod-crashloop.md ..................... Pod CrashLoopBackOff
16-node-notready.md .................... Node NotReady
scenarios-deployment-issues-1-4.md .... Deployment rollout
2-service-not-reachable.md ............. Service connectivity
scenarios-pod-issue-1.md ............... Extended pod crash guide
```

### 🟠 High Priority (Common Failures)
```
scenarios-infrastructure-issues.md .... Complete infrastructure
scenarios-pod-issue-2.md ............... Pod Pending issues
scenarios-storage-issues.md ............ PV/PVC troubleshooting
3-pvc-pending.md ....................... PVC Pending state
6-rbac-access-denied.md ................ RBAC permission issues
```

### 🟡 Medium Priority (Less Common but Important)
```
scenarios-networking-issues.md ........ Networking & DNS
11-coredns-issues.md ................... CoreDNS issues
17-kubelet-certs-expiry.md ............. Kubelet certificates
23-etcd-snapshot-restore.md ........... ETCD backup/restore
```

### 📚 Reference Files (Overviews & Indexes)
```
README.md ............................. Folder index
INDEX_AND_ORGANIZATION.md ............. This index
pod-issues.md ......................... Pod issues overview
deployment-issues.md .................. Deployment overview
storage-issues.md ..................... Storage overview
```

---

## 🔍 Quick Navigation by Error Message {#error-navigation}

**Seeing an error?** Find it here:

| Your Error | File to Check |
|-----------|---------------|
| Pod in **CrashLoopBackOff** | `1-pod-crashloop.md` or `scenarios-pod-issue-1.md` |
| Pod **Pending** forever | `scenarios-pod-issue-2.md` or `4-unschedulable-pod.md` |
| **ImagePullBackOff** | `5-image-pull-error.md` or `scenarios-pod-issue-3-8.md` |
| Container **FailedMount** | `scenarios-pod-issue-3-8.md` or `15-secret-mount-failure.md` |
| Pod **Evicted** | `10-evicted-pods.md` or `scenarios-pod-issue-3-8.md` |
| Container **OOMKilled** | `scenarios-pod-issue-3-8.md` |
| Pod **stuck Terminating** | `20-pod-stuck-terminating.md` |
| Service **not reachable** | `2-service-not-reachable.md` |
| **Unable to reach pods** | Check `2-service-not-reachable.md` or `11-coredns-issues.md` |
| **PVC stuck Pending** | `3-pvc-pending.md` or `scenarios-storage-issues.md` |
| **Node NotReady** | `16-node-notready.md` or `scenarios-infrastructure-issues.md` |
| **Kubelet certificate** expired | `17-kubelet-certs-expiry.md` |
| **API server** slow/latency | `22-api-server-high-latency.md` |
| **ETCD** issues | `23-etcd-snapshot-restore.md` or `scenarios-infrastructure-issues.md` |
| **CoreDNS** not resolving | `11-coredns-issues.md` |
| **RBAC** access denied | `6-rbac-access-denied.md` or `scenarios-config-access-issues.md` |
| **ServiceAccount** token missing | `19-missing-sa-token.md` |
| **Admission webhook** failure | `21-admission-webhook-failures.md` |
| **HPA** not scaling | `12-hpa-no-metrics.md` |
| **Ingress** 503 backend | `14-ingress-503-backend.md` |
| **Ingress TLS** mismatch | `8-ingress-tls-mismatch.md` |
| **CronJob** not running | `18-cronjob-not-running.md` |
| **PVC** resize stuck | `13-pvc-resize-stuck.md` |
| **PVC** terminating forever | `24-pvc-terminating-finalizer.md` |
| **PV** Released but not binding | `25-pv-released-not-bound.md` |

---

## 🎯 By Category {#by-category}

### Pod Troubleshooting (Most Common 🔴)
1. `1-pod-crashloop.md` - CrashLoopBackOff basics
2. `scenarios-pod-issue-1.md` - CrashLoopBackOff extended
3. `scenarios-pod-issue-2.md` - Pod Pending states
4. `scenarios-pod-issue-3-8.md` - ImagePull, Mount, Evicted, Timeout, OOM
5. `4-unschedulable-pod.md` - Unschedulable pods
6. `5-image-pull-error.md` - Image pull errors
7. `15-secret-mount-failure.md` - Secret mounting
8. `20-pod-stuck-terminating.md` - Termination issues

**Quick Start:** Begin with `1-pod-crashloop.md`

### Deployment Troubleshooting (Critical 🔴)
1. `scenarios-deployment-issues-1-4.md` - **START HERE**
2. `deployment-issues.md` - Overview
3. `12-hpa-no-metrics.md` - HPA scaling
4. `14-ingress-503-backend.md` - Ingress backend
5. `8-ingress-tls-mismatch.md` - Ingress TLS
6. `21-admission-webhook-failures.md` - Admission webhooks

**Quick Start:** Begin with `scenarios-deployment-issues-1-4.md`

### Infrastructure & Control Plane (Critical 🔴)
1. `scenarios-infrastructure-issues.md` - **START HERE** (comprehensive)
2. `16-node-notready.md` - Node NotReady
3. `17-kubelet-certs-expiry.md` - Kubelet certificates
4. `23-etcd-snapshot-restore.md` - ETCD backup/restore
5. `22-api-server-high-latency.md` - API server issues
6. `9-kube-proxy-iptables.md` - Kube-proxy
7. `node-issues.md` - Node overview
8. `control-plane-issues.md` - Control plane overview

**Quick Start:** Begin with `scenarios-infrastructure-issues.md`

### Storage & PV/PVC (High Priority 🟠)
1. `scenarios-storage-issues.md` - **START HERE** (comprehensive)
2. `3-pvc-pending.md` - PVC Pending
3. `13-pvc-resize-stuck.md` - PVC resize issues
4. `24-pvc-terminating-finalizer.md` - PVC terminating
5. `25-pv-released-not-bound.md` - PV Released issues
6. `storage-issues.md` - Storage overview

**Quick Start:** Begin with `scenarios-storage-issues.md`

### Workload Troubleshooting (Medium Priority 🟡)
1. `scenarios-workload-issues.md` - **START HERE**
2. `18-cronjob-not-running.md` - CronJob issues
3. `10-evicted-pods.md` - Pod eviction
4. `workload-issues.md` - Workload overview

**Quick Start:** Begin with `scenarios-workload-issues.md`

### Configuration & Access (High Priority 🟠)
1. `scenarios-config-access-issues.md` - **START HERE** (comprehensive)
2. `6-rbac-access-denied.md` - RBAC issues
3. `19-missing-sa-token.md` - ServiceAccount token
4. `7-podsecurity-admission.md` - Pod Security Admission
5. `auth-issues.md` - Auth overview

**Quick Start:** Begin with `scenarios-config-access-issues.md`

### Networking & DNS (Medium Priority 🟡)
1. `scenarios-networking-issues.md` - **START HERE** (comprehensive)
2. `2-service-not-reachable.md` - Service connectivity
3. `11-coredns-issues.md` - CoreDNS/DNS issues
4. `networking-issues.md` - Networking overview

**Quick Start:** Begin with `scenarios-networking-issues.md`

### Cluster Operations (Low Priority 📚)
1. `backup-restore-issues.md` - Backup/restore
2. `cluster-maintenance-issues.md` - Maintenance ops
3. `cluster-upgrade-issues.md` - Cluster upgrades

**Quick Start:** Check based on current operation

---

## 📊 Critical Path Study Guide {#critical-path-study-guide}

### For CKA Exam Preparation (Priority Order):

**Week 1: Foundation (Pod & Node Basics)**
```
Day 1-2: scenarios-pod-issue-1.md .............. CrashLoopBackOff
Day 3-4: 16-node-notready.md .................. Node issues
Day 5: scenarios-pod-issue-2.md ............... Pod Pending
Day 6-7: scenarios-infrastructure-issues.md ... Infrastructure
```

**Week 2: Deployments & Services**
```
Day 8-9: scenarios-deployment-issues-1-4.md .. Deployment rollout
Day 10: 2-service-not-reachable.md ........... Service connectivity
Day 11: 11-coredns-issues.md ................. DNS issues
Day 12-14: 23-etcd-snapshot-restore.md ....... ETCD ops
```

**Week 3: Storage & Config**
```
Day 15: scenarios-storage-issues.md .......... Storage basics
Day 16: 3-pvc-pending.md ..................... PVC issues
Day 17-18: scenarios-config-access-issues.md  RBAC & config
Day 19: 6-rbac-access-denied.md .............. RBAC deep dive
Day 20-21: Rest/Review/Practice
```

**Week 4: Advanced & Specialized**
```
Day 22: scenarios-workload-issues.md ......... CronJob & DaemonSet
Day 23: scenarios-networking-issues.md ....... Network policies
Day 24-25: Practice Scenarios & Hands-on Labs
Day 26-27: Review & Drill
Day 28: Final Practice Exam
```

---

## 🎓 Study Paths by Role

### For CKA Exam Candidates
1. **Days 1-7:** Critical Path Week 1 (Pod & Infrastructure)
2. **Days 8-14:** Critical Path Week 2 (Deployments & Cluster Ops)
3. **Days 15-21:** Critical Path Week 3 (Storage & Config)
4. **Days 22-28:** Critical Path Week 4 (Advanced & Practice)

**Files to Prioritize:**
- `scenarios-pod-issue-1.md`
- `16-node-notready.md`
- `scenarios-infrastructure-issues.md`
- `scenarios-deployment-issues-1-4.md`
- `2-service-not-reachable.md`
- `11-coredns-issues.md`

### For Platform Engineers
1. Start with infrastructure files
2. Focus on control plane: `23-etcd-snapshot-restore.md`, `22-api-server-high-latency.md`
3. Study advanced troubleshooting in each category
4. Practice cluster upgrades and maintenance

### For DevOps Engineers
1. Start with pod & deployment files
2. Focus on workload troubleshooting
3. Study storage and persistence issues
4. Practice incident response scenarios

### For Security Engineers
1. Start with RBAC: `6-rbac-access-denied.md`
2. Study pod security: `7-podsecurity-admission.md`
3. Focus on: `scenarios-config-access-issues.md`
4. Learn: `21-admission-webhook-failures.md`

---

## 🔧 How to Use Each File

### Standard File Structure:
```
1. Quick Diagnosis
   └─ Fast commands to identify the problem

2. Common Causes
   └─ 3-5 root causes with priority

3. Detailed Diagnosis
   └─ Step-by-step diagnostic workflow

4. Fixes
   └─ Remediation for each cause

5. YAML Examples
   └─ Correct vs. Incorrect templates

6. Recovery Verification
   └─ Commands to verify fix worked

7. Quick Reference
   └─ Command summary table

8. CKA Exam Tips
   └─ Exam-specific insights
```

### During an Incident:
1. **Identify error** → Use error navigation table
2. **Open file** → Jump to section
3. **Copy diagnosis commands** → Run them
4. **Find matching cause** → Apply fix
5. **Use recovery commands** → Verify fix
6. **Reference exam tips** → Learn patterns

### During Exam Study:
1. **Read** → Understand each section
2. **Copy** → Each command to muscle memory
3. **Practice** → Run in test cluster
4. **Memorize** → Common error patterns
5. **Review** → Quick reference tables

---

## 📈 File Complexity Levels

### Beginner Files (Start Here)
```
1-pod-crashloop.md
4-unschedulable-pod.md
5-image-pull-error.md
2-service-not-reachable.md
```

### Intermediate Files (Next)
```
scenarios-pod-issue-1.md
scenarios-pod-issue-2.md
16-node-notready.md
3-pvc-pending.md
6-rbac-access-denied.md
```

### Advanced Files (Deep Dives)
```
scenarios-infrastructure-issues.md
scenarios-deployment-issues-1-4.md
23-etcd-snapshot-restore.md
scenarios-config-access-issues.md
scenarios-networking-issues.md
```

### Expert Files (Specialized)
```
22-api-server-high-latency.md
24-pvc-terminating-finalizer.md
25-pv-released-not-bound.md
21-admission-webhook-failures.md
```

---

## 💡 Tips for Success

### ✅ Do:
- Start with **quick diagnosis** section
- **Run commands** as you read
- **Keep notes** of patterns you see
- **Cross-reference** between files
- **Practice** with hands-on labs
- **Memorize** quick reference tables

### ❌ Don't:
- Don't memorize every command (understand patterns)
- Don't skip the "Common Causes" section
- Don't ignore the YAML examples
- Don't skip CKA exam tips (valuable insights)
- Don't just read (practice with actual clusters)

---

## 🚀 Command Cheat Sheet (Most Used)

```bash
# Quick diagnostics
kubectl describe pod <pod> -n <ns>
kubectl logs <pod> -n <ns> --previous
kubectl get events -n <ns> --sort-by=.metadata.creationTimestamp
kubectl get all -n <ns>

# For every issue:
kubectl describe <resource> <name> -n <ns>  # See Events section
kubectl logs <pod> -n <ns>                  # Check application logs
kubectl get <resource> -o yaml              # Full resource definition

# Infrastructure
kubectl get nodes
kubectl describe node <node>
sudo journalctl -u kubelet -n 50            # SSH to node

# Storage
kubectl get pv,pvc -A
kubectl describe pv <pv>
kubectl describe pvc <pvc>

# Config/Access
kubectl auth can-i <verb> <resource>
kubectl get rolebinding -n <ns> -o yaml

# Networking
kubectl get endpoints <service>
kubectl run -it debug --image=curlimages/curl --rm -- curl <url>
```

---

## 📞 Need Help Finding Something?

| Need to Find | Look in |
|--------------|---------|
| Specific error message | [Error Navigation Table](#error-navigation) |
| Scenario by category | [By Category](#by-category) |
| Exam prep sequence | [Critical Path](#critical-path-study-guide) |
| All files organized | `INDEX_AND_ORGANIZATION.md` |
| Full documentation | `TROUBLESHOOTING_SUMMARY.md` in parent folder |

---

## ✅ Status

**Total Files:** 47  
**Total Scenarios:** 60+  
**Commands:** 600+  
**YAML Templates:** 150+  
**Status:** ✅ Complete and organized

**Ready for:**
- ✅ CKA exam preparation
- ✅ Real-world incident response
- ✅ Kubernetes troubleshooting reference
- ✅ Platform engineering documentation

---

**Last Updated:** Troubleshooting scenarios organized and indexed  
**Next Step:** Pick a file from a category above and start learning!
