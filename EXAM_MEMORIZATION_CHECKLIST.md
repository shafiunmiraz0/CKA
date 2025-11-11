# CKA Exam Memorization Checklist

**Memorize these before the exam. If you can do these 50+ commands quickly, you'll pass.**

> **Pro tip:** Read through this 2-3 times the day before exam. You don't need to memorize syntax perfectly; muscle memory is key.

---

## Essential kubectl & kubeadm Commands (Must Memorize)

### 1. Cluster Architecture (25% of exam)

**Initialization & Node Management**
```bash
# Initialize control plane
kubeadm init --pod-network-cidr=10.244.0.0/16

# Print join command (save this during init)
kubeadm token create --print-join-command

# Join worker to cluster
kubeadm join 10.0.0.1:6443 --token <token> --discovery-token-ca-cert-hash sha256:<hash>

# Reset node (remove from cluster)
kubeadm reset -f

# Certificate management
kubeadm certs check-expiration
kubeadm certs renew all
```

**Node Maintenance**
```bash
# Prepare node for maintenance
kubectl cordon <node>

# Drain pods gracefully (evict all pods)
kubectl drain <node> --ignore-daemonsets --delete-local-data

# Resume scheduling on node
kubectl uncordon <node>

# Check node status
kubectl get nodes -o wide
kubectl describe node <node-name>
```

**Cluster Info**
```bash
# View current cluster info
kubectl cluster-info
kubectl config current-context
kubectl config view --minify

# Check API server health
kubectl get --raw /healthz
kubectl get componentstatuses
```

---

### 2. Workloads & Scheduling (15% of exam)

**Deployment Management**
```bash
# Create deployment
kubectl create deployment name --image=nginx:1.21 --replicas=3

# Apply from YAML file
kubectl apply -f deployment.yaml

# Get deployments
kubectl get deployments
kubectl get deploy -o wide
kubectl describe deploy <name>

# Scale deployment
kubectl scale deployment/<name> --replicas=5

# Update image
kubectl set image deployment/<name> container-name=new-image:tag

# Or use patch (complex but powerful)
kubectl patch deploy <name> -p '{"spec":{"template":{"spec":{"containers":[{"name":"app","image":"new:tag"}]}}}}'
```

**Rollout Management** (Critical for troubleshooting)
```bash
# Check rollout status
kubectl rollout status deployment/<name>

# View rollout history
kubectl rollout history deployment/<name>

# Show details for specific revision
kubectl rollout history deployment/<name> --revision=2

# Undo to previous revision
kubectl rollout undo deployment/<name>

# Undo to specific revision
kubectl rollout undo deployment/<name> --to-revision=1

# Pause rollout (for canary/testing)
kubectl rollout pause deployment/<name>

# Resume rollout
kubectl rollout resume deployment/<name>

# Force restart pods
kubectl rollout restart deployment/<name>
```

**Pod Management**
```bash
# Get pods
kubectl get pods -n <ns>
kubectl get pods -o wide
kubectl describe pod <name>

# Create pod directly
kubectl run debug --image=busybox --restart=Never -- sleep 1000

# Delete pod
kubectl delete pod <name>

# Force delete (stuck pod)
kubectl delete pod <name> --grace-period=0 --force

# Logs
kubectl logs <pod>
kubectl logs <pod> --previous  # If pod crashed and restarted
kubectl logs <pod> -c <container>  # Specific container
kubectl logs -f <pod>  # Tail logs
```

**Scheduling Primitives**
```bash
# Node selector (simple key=value)
# Add to pod.spec:
# nodeSelector:
#   disk: ssd

# Taints & tolerations
kubectl taint nodes <node> key=value:NoSchedule
kubectl taint nodes <node> key:NoSchedule-  # Remove taint

# Affinity (more complex; use YAML template)
# affinity:
#   nodeAffinity:
#     requiredDuringSchedulingIgnoredDuringExecution:
#       nodeSelectorTerms:
#       - matchExpressions:
#         - key: kubernetes.io/hostname
#           operator: In
#           values:
#           - node1
```

---

### 3. Services & Networking (20% of exam)

**Service Management**
```bash
# Expose deployment as ClusterIP (default)
kubectl expose deployment/<name> --port=80 --target-port=8080

# Expose as NodePort
kubectl expose deployment/<name> --type=NodePort --port=80

# Expose as LoadBalancer
kubectl expose deployment/<name> --type=LoadBalancer --port=80

# Get services
kubectl get svc
kubectl get svc -n <ns>
kubectl describe svc <name>

# Check endpoints (shows which pods are behind service)
kubectl get endpoints <svc-name>
```

**Port Forwarding & Testing**
```bash
# Port forward to service
kubectl port-forward svc/<service-name> 8080:80

# Port forward to pod
kubectl port-forward pod/<pod-name> 8080:80

# DNS testing pod
kubectl run -i --tty dnsutils --image=tianon/dnsutils --restart=Never --rm -- bash

# Inside DNS pod, test:
nslookup kubernetes.default
nslookup <service-name>
nslookup <service-name>.<namespace>.svc.cluster.local
```

**Ingress**
```bash
# List ingress
kubectl get ingress
kubectl describe ingress <name>

# Apply ingress
kubectl apply -f ingress.yaml

# Check ingress controller
kubectl get pods -n ingress-nginx
```

**NetworkPolicy** (Security)
```bash
# List policies
kubectl get networkpolicy
kubectl get netpol -n <ns>

# Apply policy
kubectl apply -f networkpolicy.yaml
```

---

### 4. Storage (10% of exam)

**PersistentVolumes (PV)**
```bash
# List PVs
kubectl get pv

# Describe PV
kubectl describe pv <pv-name>

# Create PV from YAML
kubectl apply -f pv.yaml
```

**PersistentVolumeClaims (PVC)**
```bash
# List PVCs
kubectl get pvc
kubectl get pvc -n <ns>

# Describe PVC (shows if Bound/Pending)
kubectl describe pvc <pvc-name> -n <ns>

# Apply PVC
kubectl apply -f pvc.yaml
```

**StorageClass**
```bash
# List storage classes
kubectl get storageclass

# Describe storage class
kubectl describe sc <name>

# Set default storage class
kubectl patch storageclass <name> -p '{"metadata":{"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'
```

**PVC Resizing**
```bash
# Resize PVC (must have allowVolumeExpansion: true)
kubectl patch pvc <pvc-name> -p '{"spec":{"resources":{"requests":{"storage":"20Gi"}}}}'

# Monitor resize status
kubectl describe pvc <pvc-name> | grep -A 5 Conditions
```

---

### 5. Security & RBAC (5-10% of exam)

**ServiceAccount & RBAC**
```bash
# Create service account
kubectl create serviceaccount <name> -n <ns>

# Create role
kubectl create role <name> --verb=get,list,watch --resource=pods -n <ns>

# Create role binding
kubectl create rolebinding <name> --role=<role-name> --serviceaccount=<ns>:<sa-name> -n <ns>

# Create cluster role
kubectl create clusterrole <name> --verb=get,list --resource=nodes

# Create cluster role binding
kubectl create clusterrolebinding <name> --clusterrole=<role-name> --user=<user-name>
```

**RBAC Testing**
```bash
# Test if user can perform action
kubectl auth can-i create pods -n <ns>

# Test as another user
kubectl auth can-i get pods -n <ns> --as=system:serviceaccount:default:myuser

# List all actions I can do
kubectl auth can-i --list
```

**Pod Security & Secrets**
```bash
# Create secret
kubectl create secret generic <name> --from-literal=key=value

# Create docker-registry secret
kubectl create secret docker-registry <name> --docker-server=... --docker-username=... --docker-password=...

# Get secret
kubectl get secrets
kubectl describe secret <name>

# Apply pod security policy (or PSA via namespace labels)
kubectl apply -f podsecurity-namespace-labels.yaml
```

---

### 6. Troubleshooting (30% of exam) — Quick Diagnostic Sequence

**This sequence solves 80% of troubleshooting problems:**

```bash
# Step 1: Overview of resources
kubectl get all -n <ns>

# Step 2: Get detailed status
kubectl describe pod/<pod-name> -n <ns>

# Step 3: Check logs (current)
kubectl logs <pod-name> -n <ns>

# Step 4: Check logs (if pod crashed and restarted)
kubectl logs <pod-name> -n <ns> --previous

# Step 5: View recent events (sorted by time)
kubectl get events -n <ns> --sort-by=.metadata.creationTimestamp

# Step 6: Execute into pod for inspection
kubectl exec -it <pod-name> -n <ns> -- /bin/sh

# Step 7: Check node status (if scheduling issue)
kubectl describe node <node-name>

# Step 8: Check metrics (if resource issue, needs metrics-server)
kubectl top nodes
kubectl top pods -n <ns>
```

**Common Issues & Quick Fixes:**

| Issue | Diagnostic | Fix |
|-------|-----------|-----|
| **CrashLoopBackOff** | `kubectl logs <pod> --previous` | Check app exit code; fix command/config |
| **Pending Pod** | `kubectl describe pod` (check events) | Fix resource requests, taint/selector, PVC |
| **ImagePullBackOff** | `kubectl describe pod` (check image) | Fix image name, registry, imagePullSecret |
| **Service not reachable** | `kubectl get endpoints <svc>` | Fix service selector labels |
| **PVC Pending** | `kubectl describe pvc` | Fix storage class, capacity, access mode |

---

## Essential YAML Patterns to Memorize

### Deployment Template
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: app
spec:
  replicas: 3
  selector:
    matchLabels:
      app: app
  template:
    metadata:
      labels:
        app: app
    spec:
      containers:
      - name: app
        image: nginx:1.21
        ports:
        - containerPort: 80
        resources:
          requests:
            cpu: 100m
            memory: 128Mi
          limits:
            cpu: 500m
            memory: 256Mi
```

### Service Template
```yaml
apiVersion: v1
kind: Service
metadata:
  name: app-svc
spec:
  type: ClusterIP  # or NodePort, LoadBalancer
  selector:
    app: app
  ports:
  - port: 80
    targetPort: 80
```

### PersistentVolumeClaim Template
```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: app-pvc
spec:
  accessModes:
  - ReadWriteOnce
  resources:
    requests:
      storage: 10Gi
  storageClassName: standard  # or leave blank for default
```

### NetworkPolicy Template
```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: deny-all
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  - Egress
```

### Role & RoleBinding Template
```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: pod-reader
rules:
- apiGroups: [""]
  resources: ["pods"]
  verbs: ["get", "list", "watch"]

---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: read-pods
subjects:
- kind: ServiceAccount
  name: default
  namespace: default
roleRef:
  kind: Role
  name: pod-reader
  apiGroup: rbac.authorization.k8s.io
```

---

## Command Shortcuts to Speed Up

**If exam allows it, create shell aliases (add to `.bashrc` before exam):**
```bash
alias k=kubectl
alias kg='kubectl get'
alias kd='kubectl describe'
alias kl='kubectl logs'
alias ke='kubectl exec -it'
alias ka='kubectl apply -f'
```

**Quick copy/paste patterns:**
- `kubectl get <resource> -A` → Show all across namespaces
- `kubectl get <resource> -n <ns> -o wide` → Detailed view
- `kubectl get <resource> -o yaml` → View YAML configuration
- `kubectl describe <resource> <name>` → Deep debug info

---

## 🎯 The 20 Commands You MUST Know

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

**If you can execute these 20 commands instantly, you'll score 60%+**

---

## Pre-Exam Review (5 Minutes)

### Read these sections in order:
- [ ] **Troubleshooting Sequence** (6 steps above)
- [ ] **The 20 Commands** (list above)
- [ ] **Common Issues & Quick Fixes** (table above)

### Then review your domain:
- [ ] If your exam focuses on Deployments → Read Workloads section
- [ ] If your exam focuses on Networking → Read Services section
- [ ] If your exam focuses on Storage → Read Storage section

---

## Exam Day Checklist

**Before clicking "Start Exam":**
- [ ] All 20 commands above ready to type or copy/paste
- [ ] YAML templates memorized (at least structure)
- [ ] Troubleshooting sequence memorized (6 steps)
- [ ] Comfortable with `kubectl describe` and `kubectl logs`
- [ ] Know the difference between `get`, `describe`, `apply`, `edit`

**During exam:**
- [ ] Read ALL problems first (5 min)
- [ ] Do easy problems first (avoid time traps)
- [ ] When stuck on a problem, immediately use diagnostic sequence
- [ ] Copy/paste YAML from GitHub repo (don't type from scratch)
- [ ] Verify each problem before moving to next

---

## Final Thoughts

**Remember:**
- You don't need to memorize syntax perfectly
- You need muscle memory for speed
- 70% = passing; you don't need perfection
- Speed > Accuracy for most problems
- Read problem carefully before starting

**Practice routine:**
- Do 1 full practice exam (2 hours, timed)
- Review this checklist 2-3 times
- Sleep well the night before

**Good luck! You've prepared well. 🚀**

