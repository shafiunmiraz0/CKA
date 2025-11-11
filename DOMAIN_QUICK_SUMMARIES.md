# CKA Domain Quick Summaries — One-Page Reference Per Topic

**Use this for last-minute review before exam. Each domain has 5-7 essential commands and 2-3 key patterns.**

---

## Domain 1: Cluster Architecture, Installation & Configuration (25% of exam)

**Where you spend time:** kubeadm commands, node management, certificates, cluster setup

### Essential Commands
```bash
# Initialize cluster
kubeadm init --pod-network-cidr=10.244.0.0/16

# Join worker (copy from init output)
kubeadm join 10.0.0.1:6443 --token <token> --discovery-token-ca-cert-hash sha256:<hash>

# Get new token
kubeadm token create --print-join-command

# Cordon/drain/uncordon for maintenance
kubectl cordon <node>
kubectl drain <node> --ignore-daemonsets --delete-local-data
kubectl uncordon <node>

# Certificate management
kubeadm certs check-expiration
kubeadm certs renew all

# Cluster info
kubectl cluster-info
kubectl get --raw /healthz
```

### Key YAML Pattern
```yaml
# ClusterConfiguration for advanced init
apiVersion: kubeadm.k8s.io/v1beta3
kind: ClusterConfiguration
kubernetesVersion: stable
networking:
  podSubnet: "10.244.0.0/16"
```

### Quick Troubleshooting
- **Node NotReady?** → `kubectl describe node <node>` (check conditions)
- **Kubelet crashed?** → SSH to node: `systemctl status kubelet` & `sudo journalctl -u kubelet -n 50`
- **API not responding?** → `kubectl get --raw /healthz`

### Exam Tips
- Save the full `kubeadm join` command from init output (you'll need it)
- Know the difference between `cordon` (stop new pods) vs `drain` (evict existing pods)
- Always reset nodes (`kubeadm reset -f`) before re-initializing

---

## Domain 2: Workloads & Scheduling (15% of exam)

**Where you spend time:** Deployments, scaling, rollouts, updates, pod scheduling

### Essential Commands
```bash
# Create & apply
kubectl create deployment app --image=nginx:1.21 --replicas=3
kubectl apply -f deployment.yaml

# Scale
kubectl scale deployment/<name> --replicas=5

# Update image
kubectl set image deployment/<name> app=nginx:1.22

# Rollout (most important!)
kubectl rollout status deployment/<name>           # Watch progress
kubectl rollout history deployment/<name>          # View revisions
kubectl rollout undo deployment/<name>             # Undo to previous
kubectl rollout undo deployment/<name> --to-revision=2  # Undo to specific

# Pause & resume (for canary)
kubectl rollout pause deployment/<name>
kubectl rollout resume deployment/<name>

# Pod logs & debugging
kubectl logs <pod> [--previous] [-c <container>]
kubectl exec -it <pod> -- /bin/sh
```

### Key YAML Patterns
```yaml
# Deployment with probes & resources
replicas: 3
readinessProbe:
  httpGet: {path: /, port: 8080}
  initialDelaySeconds: 5
livenessProbe:
  httpGet: {path: /health, port: 8080}
  initialDelaySeconds: 15
resources:
  requests: {cpu: 100m, memory: 128Mi}
  limits: {cpu: 500m, memory: 256Mi}

# Node selector (simple)
nodeSelector: {disk: ssd}

# Tolerations (for taints)
tolerations:
- key: taint-key
  operator: Equal
  value: taint-value
  effect: NoSchedule
```

### Quick Troubleshooting
- **CrashLoopBackOff?** → `kubectl logs <pod> --previous` (see why it crashed)
- **Pods not updating?** → `kubectl rollout status` (check progress) + `kubectl get rs` (check old vs new)
- **Can't scale?** → `kubectl describe deploy` (check status conditions)

### Exam Tips
- `rollout undo` is your best friend for broken deployments
- Always check `revisionHistoryLimit` (default=10, controls how many revisions to keep)
- `kubectl rollout restart` force restarts all pods (useful for certificate rotations)

---

## Domain 3: Services & Networking (20% of exam)

**Where you spend time:** Service types, DNS, Ingress, NetworkPolicy

### Essential Commands
```bash
# Expose deployment as service
kubectl expose deployment/<name> --port=80 --target-port=8080  # ClusterIP
kubectl expose deployment/<name> --type=NodePort --port=80      # NodePort
kubectl expose deployment/<name> --type=LoadBalancer --port=80  # LoadBalancer

# Service info
kubectl get svc
kubectl get endpoints <svc>      # Which pods are backing the service?
kubectl describe svc <name>

# Port forward (for testing)
kubectl port-forward svc/<name> 8080:80

# DNS testing pod
kubectl run -it --image=dnsutils dnsutils --restart=Never -- bash
# Then inside: nslookup <service-name>

# Ingress
kubectl apply -f ingress.yaml
kubectl get ingress
kubectl describe ingress <name>

# NetworkPolicy
kubectl apply -f networkpolicy.yaml
kubectl get netpol -n <ns>
```

### Key YAML Patterns
```yaml
# Service (ClusterIP - internal)
apiVersion: v1
kind: Service
metadata: {name: my-svc}
spec:
  type: ClusterIP
  selector: {app: myapp}
  ports:
  - port: 80
    targetPort: 8080

# NetworkPolicy (deny all, then allow)
spec:
  podSelector:
    matchLabels: {app: web}
  ingress:
  - from:
    - podSelector: {matchLabels: {role: client}}
    ports:
    - protocol: TCP
      port: 8080
```

### Quick Troubleshooting
- **Service not reachable?** → `kubectl get endpoints <svc>` (check if pods are backing it)
- **DNS not resolving?** → `kubectl logs -n kube-system -l k8s-app=kube-dns` (check CoreDNS)
- **Endpoints empty?** → Pod labels don't match service selector; check `kubectl describe svc <name>`

### Exam Tips
- Service DNS name: `<service-name>.<namespace>.svc.cluster.local`
- Always verify pod labels match service selector (`kubectl get pods --show-labels`)
- Use port-forward to quickly test service connectivity without Ingress

---

## Domain 4: Storage (10% of exam)

**Where you spend time:** PV, PVC, StorageClass, volume mounting

### Essential Commands
```bash
# PersistentVolume
kubectl get pv
kubectl describe pv <name>

# PersistentVolumeClaim (most important!)
kubectl get pvc -n <ns>
kubectl describe pvc <name> -n <ns>  # Check if Bound or Pending

# StorageClass
kubectl get storageclass
kubectl describe sc <name>

# Resize PVC
kubectl patch pvc <name> -n <ns> -p '{"spec":{"resources":{"requests":{"storage":"20Gi"}}}}'

# Check volume mounted in pod
kubectl exec <pod> -- df -h  # See mounted filesystems
```

### Key YAML Patterns
```yaml
# StorageClass (dynamic provisioning)
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata: {name: fast}
provisioner: ebs.csi.aws.com
allowVolumeExpansion: true

# PVC (static or dynamic)
apiVersion: v1
kind: PersistentVolumeClaim
metadata: {name: my-pvc}
spec:
  accessModes: [ReadWriteOnce]
  resources: {requests: {storage: 10Gi}}
  storageClassName: fast

# Pod with volume mount
volumes:
- name: storage
  persistentVolumeClaim: {claimName: my-pvc}
containers:
- name: app
  volumeMounts:
  - mountPath: /data
    name: storage
```

### Quick Troubleshooting
- **PVC Pending?** → `kubectl describe pvc` (check events, usually StorageClass/provisioner issue)
- **Pod can't write to volume?** → Check accessMode (RWO=single pod, RWX=multiple pods)
- **Resize stuck?** → `kubectl describe pvc` (check conditions); must have `allowVolumeExpansion: true`

### Exam Tips
- PV is cluster-scoped; PVC is namespace-scoped
- One PV = One PVC (multiple pods can mount same PVC if RWX)
- `kubectl get pvc -A` shows all PVCs across namespaces quickly
- Static vs Dynamic: Dynamic = StorageClass + PVC auto-creates PV

---

## Domain 5: Security & RBAC (5-10% of exam)

**Where you spend time:** RBAC roles, service accounts, secrets, policies

### Essential Commands
```bash
# ServiceAccount
kubectl create serviceaccount <name> -n <ns>
kubectl get sa -n <ns>

# Role (namespace-scoped)
kubectl create role pod-reader --verb=get,list --resource=pods -n <ns>

# RoleBinding (namespace-scoped)
kubectl create rolebinding binding --role=pod-reader --serviceaccount=<ns>:<sa> -n <ns>

# ClusterRole & ClusterRoleBinding (cluster-wide)
kubectl create clusterrole reader --verb=get --resource=nodes
kubectl create clusterrolebinding binding --clusterrole=reader --user=<username>

# Test RBAC (can I do this?)
kubectl auth can-i create pods -n <ns>
kubectl auth can-i get pods -n <ns> --as=system:serviceaccount:default:user

# Secrets & ConfigMaps
kubectl create secret generic <name> --from-literal=key=value
kubectl create configmap <name> --from-literal=key=value
```

### Key YAML Patterns
```yaml
# Role (namespace-scoped)
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata: {name: pod-reader, namespace: default}
rules:
- apiGroups: [""]
  resources: ["pods"]
  verbs: ["get", "list", "watch"]

# RoleBinding
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata: {name: read-pods}
subjects:
- kind: ServiceAccount
  name: default
roleRef: {kind: Role, name: pod-reader}

# Pod Security Context
securityContext:
  runAsUser: 1000
  runAsNonRoot: true
  fsGroup: 2000
  readOnlyRootFilesystem: true
```

### Quick Troubleshooting
- **Permission denied?** → `kubectl auth can-i <verb> <resource>` (check permissions)
- **ServiceAccount token not mounted?** → Check automountServiceAccountToken field

### Exam Tips
- Namespace-scoped = Role/RoleBinding (use for most tasks)
- Cluster-scoped = ClusterRole/ClusterRoleBinding (use for nodes, namespaces)
- Always test with `kubectl auth can-i` before declaring victory

---

## Domain 6: Troubleshooting (30% of exam) — The Diagnostic Playbook

**Where you spend time:** Diagnosing broken deployments, services, networking, storage

### Universal Diagnostic Sequence (Solves 80% of problems!)
```bash
# 1. Overview
kubectl get all -n <ns>

# 2. Deep dive into problem resource (MOST IMPORTANT!)
kubectl describe pod/<pod> -n <ns>

# 3. Logs (why did it fail?)
kubectl logs <pod> -n <ns> [--previous]

# 4. Recent cluster events
kubectl get events -n <ns> --sort-by=.metadata.creationTimestamp

# 5. Execute into pod (if running)
kubectl exec -it <pod> -n <ns> -- /bin/sh

# 6. Check node (if scheduling issue)
kubectl describe node <node>
```

### Common Issue Patterns & Fixes

| Symptom | Diagnosis | Fix |
|---------|-----------|-----|
| **Pod CrashLoopBackOff** | `kubectl logs --previous` | Fix app command, env vars, or config |
| **Pod Pending** | `kubectl describe pod` (events) | Fix resource requests, taints, selectors, or PVC |
| **ImagePullBackOff** | `kubectl describe pod` (image name/registry) | Fix image name or add imagePullSecret |
| **Service no endpoints** | `kubectl get endpoints <svc>` | Fix pod labels to match selector |
| **PVC Pending** | `kubectl describe pvc` (events) | Fix StorageClass or provisioner |
| **Deployment not updating** | `kubectl rollout status` + `kubectl get rs` | Check old ReplicaSet vs new |
| **Node NotReady** | `kubectl describe node` (conditions) | Check kubelet, disk space, or certs |
| **RBAC Permission denied** | `kubectl auth can-i <verb> <resource>` | Check Role/RoleBinding |

### Exam Tips
- Read `kubectl describe` output top-to-bottom; it usually shows the problem
- Always check Events section (bottom) — that's where Kubernetes logs failures
- Use `--previous` for logs when pod has restarted
- 30% of exam = troubleshooting; master this diagnostic sequence!

---

## 🎯 Quick Study Plan (Before Exam)

### Day 1: Read All Domains
- Read all 6 domain README files (1 hour each)
- 6 hours total

### Day 2-3: Practice Scenarios
- Work through 5-10 scenarios from `Troubleshooting/issue-scenarios/`
- 3 hours per day

### Day 4: Full Practice Exam
- Complete a 2-hour practice exam (all 17 problems)
- Review errors and missing knowledge

### Day 5: Memorization & Review
- Read `EXAM_MEMORIZATION_CHECKLIST.md` 2-3 times
- Practice the top 20 commands from muscle memory
- 1-2 hours

### Day 6: Rest & Final Review
- Read this file (`DOMAIN_QUICK_SUMMARIES.md`)
- Read `EXAM_QUICK_START.md`
- Get good sleep

---

## 📊 Scoring Strategy

- **Solve 11/17 problems** → ~70% (passing)
- **Solve 13/17 problems** → ~85% (good pass)
- **Solve 15/17 problems** → ~95% (excellent)

**Strategy:** Focus on easy + medium problems first. Don't get stuck on hard problems.

---

## 🔗 Quick Links to Deep Dives

- **Full command reference:** `QUICK_COMMANDS_ALL_DOMAINS.md`
- **Complete checklist:** `EXAM_MEMORIZATION_CHECKLIST.md`
- **Exam strategy:** `EXAM_QUICK_START.md`
- **Troubleshooting scenarios:** `Troubleshooting/issue-scenarios/`

---

**Last Updated:** November 2024  
**For CKA Exam:** Kubernetes v1.30+  
**Exam Duration:** 2 hours, 17 problems  
**Passing Score:** ~70%

**You've got this! 🚀**

