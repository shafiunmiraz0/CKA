# CKA Quick Commands — All Domains Reference

**One-page command cheat sheet organized by exam domain. Open this during exam for instant command lookup.**

> **How to use:** Ctrl+F to search for your problem domain (e.g., "Deployment", "Service", "Storage")

---

## 🔍 Quick Search Index

- [Cluster Architecture (25%)](#cluster-architecture)
- [Workloads & Scheduling (15%)](#workloads--scheduling)
- [Services & Networking (20%)](#services--networking)
- [Storage (10%)](#storage)
- [Security & RBAC (5-10%)](#security--rbac)
- [Troubleshooting (30%)](#troubleshooting)

---

## Cluster Architecture

### Initialize & Join Cluster
```bash
# Initialize control plane
kubeadm init --pod-network-cidr=10.244.0.0/16

# Get join command (save this!)
kubeadm token create --print-join-command

# Join worker (paste the command from above)
kubeadm join 10.0.0.1:6443 --token <token> --discovery-token-ca-cert-hash sha256:<hash>

# Reset node (remove from cluster, dangerous!)
kubeadm reset -f

# Remove CNI/iptables after reset
sudo rm -rf /etc/cni/net.d && sudo iptables -F
```

### Cluster Info & Status
```bash
# Current cluster and context
kubectl cluster-info
kubectl config current-context
kubectl config view --minify

# Check API server and components health
kubectl get --raw /healthz
kubectl get componentstatuses
kubectl get --raw /readyz

# List nodes
kubectl get nodes -o wide
kubectl describe node <node>
```

### Node Maintenance (Upgrades & Drains)
```bash
# Cordon node (stop new pods from scheduling)
kubectl cordon <node>

# Drain node (evict all pods, prepare for maintenance)
kubectl drain <node> --ignore-daemonsets --delete-local-data

# Uncordon node (allow scheduling again)
kubectl uncordon <node>

# Check kubelet status on node (SSH to node first)
systemctl status kubelet
sudo journalctl -u kubelet -n 200

# Control plane manifests location
cat /etc/kubernetes/manifests/kube-apiserver.yaml
```

### Certificate & Authentication
```bash
# Check certificate expiration
kubeadm certs check-expiration

# Renew all certificates
kubeadm certs renew all

# Setup kubeconfig for non-root user
mkdir -p $HOME/.kube
sudo cp /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
```

### Static Pod Management
```bash
# Static manifests are in /etc/kubernetes/manifests/
# Any YAML in this folder automatically runs as pod
sudo cp pod.yaml /etc/kubernetes/manifests/
sudo rm /etc/kubernetes/manifests/pod.yaml
```

---

## Workloads & Scheduling

### Create & Apply Deployments
```bash
# Create deployment (imperative)
kubectl create deployment myapp --image=nginx:1.21 --replicas=3

# Apply from YAML (declarative, preferred)
kubectl apply -f deployment.yaml

# Check deployment status
kubectl get deployments
kubectl get deploy -o wide
kubectl describe deploy <name>
```

### Scale & Update
```bash
# Scale deployment (change replica count)
kubectl scale deployment/<name> --replicas=5

# Update image (single container)
kubectl set image deployment/<name> container-name=new-image:tag

# Update image (multiple containers)
kubectl set image deployment/<name> \
  container1=image1:tag \
  container2=image2:tag

# Update other fields (use patch)
kubectl patch deployment/<name> -p '{"spec":{"template":{"spec":{"containers":[{"name":"app","image":"new:tag"}]}}}}'
```

### Rollout Management (Update & Undo)
```bash
# Watch rollout progress
kubectl rollout status deployment/<name>

# View rollout history (revisions)
kubectl rollout history deployment/<name>

# View specific revision details
kubectl rollout history deployment/<name> --revision=2

# Undo to previous revision
kubectl rollout undo deployment/<name>

# Undo to specific revision
kubectl rollout undo deployment/<name> --to-revision=1

# Pause rollout (for canary deployments)
kubectl rollout pause deployment/<name>

# Resume rollout
kubectl rollout resume deployment/<name>

# Force restart all pods (recreate)
kubectl rollout restart deployment/<name>
```

### Pod Management
```bash
# List pods
kubectl get pods -n <ns>
kubectl get pods -o wide  # Show node + IP
kubectl get pods --all-namespaces

# Pod details
kubectl describe pod <pod> -n <ns>

# Pod YAML
kubectl get pod <pod> -o yaml

# Create pod directly (quick testing)
kubectl run debug --image=busybox --restart=Never -- sleep 1000

# Delete pod
kubectl delete pod <pod> -n <ns>

# Force delete stuck pod
kubectl delete pod <pod> -n <ns> --grace-period=0 --force

# Logs
kubectl logs <pod> -n <ns>
kubectl logs <pod> -n <ns> --previous  # If crashed
kubectl logs <pod> -n <ns> -c <container>  # Specific container
kubectl logs -f <pod> -n <ns>  # Tail (follow)
kubectl logs <pod> -n <ns> --since=5m  # Last 5 min
```

### Probes, Resources & Lifecycle
```bash
# Readiness probe (example YAML)
readinessProbe:
  httpGet:
    path: /ready
    port: 8080
  initialDelaySeconds: 5
  periodSeconds: 5

# Liveness probe (example YAML)
livenessProbe:
  exec:
    command: [cat, /tmp/healthy]
  initialDelaySeconds: 15
  periodSeconds: 20

# Resource requests & limits (example YAML)
resources:
  requests:
    cpu: 100m
    memory: 128Mi
  limits:
    cpu: 500m
    memory: 256Mi
```

### Scheduling: Node Selector, Affinity, Tolerations
```bash
# Node selector (simple key=value)
# In pod spec: nodeSelector: {disk: ssd}
kubectl label node <node> disk=ssd

# Check node labels
kubectl get nodes --show-labels

# Taints & Tolerations
# Add taint to node
kubectl taint nodes <node> key=value:NoSchedule

# Remove taint
kubectl taint nodes <node> key:NoSchedule-

# Toleration in pod spec (example YAML):
tolerations:
- key: key
  operator: Equal
  value: value
  effect: NoSchedule

# Pod affinity (example YAML, complex)
affinity:
  nodeAffinity:
    requiredDuringSchedulingIgnoredDuringExecution:
      nodeSelectorTerms:
      - matchExpressions:
        - key: kubernetes.io/hostname
          operator: In
          values:
          - node1
```

### DaemonSet, StatefulSet, Job
```bash
# DaemonSet (runs on all nodes)
kubectl apply -f daemonset.yaml
kubectl get daemonsets

# StatefulSet (stateful workloads)
kubectl apply -f statefulset.yaml
kubectl get statefulsets

# Job (one-time task)
kubectl create job my-job --image=python:3.9 -- python script.py
kubectl get jobs
kubectl describe job <job-name>
kubectl logs job/<job-name>

# Delete job and pods
kubectl delete job <job-name> --cascade=foreground

# CronJob (scheduled job)
kubectl apply -f cronjob.yaml
kubectl get cronjobs
kubectl describe cronjob <name>
```

---

## Services & Networking

### Create & Expose Services
```bash
# Expose deployment as ClusterIP (internal)
kubectl expose deployment/<name> --port=80 --target-port=8080 --name=my-svc

# Expose as NodePort (external, each node)
kubectl expose deployment/<name> --type=NodePort --port=80 --name=my-svc

# Expose as LoadBalancer (cloud provider)
kubectl expose deployment/<name> --type=LoadBalancer --port=80 --name=my-svc

# Apply service from YAML
kubectl apply -f service.yaml

# List services
kubectl get svc
kubectl get svc -n <ns>
kubectl describe svc <name>

# View service details (YAML)
kubectl get svc <name> -o yaml
```

### Endpoints & Service Discovery
```bash
# Check service endpoints (which pods are backing it)
kubectl get endpoints <svc>

# Service DNS name
# <service-name>.<namespace>.svc.cluster.local

# Test DNS resolution (inside DNS pod)
nslookup kubernetes.default
nslookup <service-name>
nslookup <service-name>.<namespace>.svc.cluster.local
dig <service-name>

# Test HTTP connectivity
curl http://<service-name>
curl http://<service-name>.<namespace>
```

### Port Forwarding
```bash
# Port forward to service
kubectl port-forward svc/<svc-name> 8080:80

# Port forward to pod
kubectl port-forward pod/<pod-name> 8080:80

# Port forward to any port
kubectl port-forward svc/my-svc 8888:80
```

### Ingress
```bash
# List ingress
kubectl get ingress
kubectl get ingress -n <ns>
kubectl describe ingress <name>

# View ingress YAML
kubectl get ingress <name> -o yaml

# Apply ingress
kubectl apply -f ingress.yaml

# Check ingress controller pods
kubectl get pods -n ingress-nginx

# Debug ingress controller
kubectl logs -n ingress-nginx -l app.kubernetes.io/name=ingress-nginx

# Test ingress (from inside cluster)
curl http://example.local/path
```

### Networking Debugging
```bash
# Check CoreDNS pods (DNS provider)
kubectl get pods -n kube-system -l k8s-app=kube-dns

# Check CoreDNS logs
kubectl logs -n kube-system -l k8s-app=kube-dns

# Inspect CoreDNS config
kubectl get configmap coredns -n kube-system -o yaml

# Check kube-proxy
kubectl get pods -n kube-system -l k8s-app=kube-proxy
kubectl describe daemonset kube-proxy -n kube-system
```

### NetworkPolicy
```bash
# List network policies
kubectl get networkpolicy
kubectl get netpol -n <ns>

# Describe policy
kubectl describe netpol <name>

# Apply policy
kubectl apply -f networkpolicy.yaml

# Deny all traffic (ingress)
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: deny-all
spec:
  podSelector: {}
  policyTypes:
  - Ingress

# Allow specific traffic (example YAML)
spec:
  podSelector:
    matchLabels:
      app: web
  ingress:
  - from:
    - podSelector:
        matchLabels:
          app: client
    ports:
    - protocol: TCP
      port: 8080
```

---

## Storage

### PersistentVolume (PV)
```bash
# List PVs
kubectl get pv
kubectl get pv -o wide

# Describe PV
kubectl describe pv <pv-name>

# View PV YAML
kubectl get pv <pv-name> -o yaml

# Create PV (static provisioning)
kubectl apply -f pv.yaml

# Delete PV
kubectl delete pv <pv-name>

# PV Status: Available → Bound → Released (if PVC deleted, reclaimPolicy=Retain)
```

### PersistentVolumeClaim (PVC)
```bash
# List PVCs
kubectl get pvc
kubectl get pvc -n <ns>
kubectl get pvc -A  # All namespaces

# Describe PVC (shows if Bound/Pending)
kubectl describe pvc <pvc-name> -n <ns>

# View PVC YAML
kubectl get pvc <pvc-name> -o yaml

# Create PVC (dynamic or static)
kubectl apply -f pvc.yaml

# Delete PVC
kubectl delete pvc <pvc-name> -n <ns>

# Check if PVC is bound to PV
kubectl get pvc <pvc-name> -o jsonpath='{.spec.volumeName}'
```

### StorageClass
```bash
# List storage classes
kubectl get storageclass
kubectl get sc

# Describe storage class
kubectl describe sc <name>

# Set default storage class
kubectl patch storageclass <name> -p '{"metadata":{"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'

# Check if storage class is default
kubectl get storageclass <name> -o jsonpath='{.metadata.annotations.storageclass\.kubernetes\.io/is-default-class}'

# Apply storage class
kubectl apply -f storageclass.yaml
```

### PVC Resizing
```bash
# Resize PVC (must have allowVolumeExpansion: true)
kubectl patch pvc <pvc-name> -p '{"spec":{"resources":{"requests":{"storage":"20Gi"}}}}'

# Monitor resize status
kubectl describe pvc <pvc-name>
# Look for "conditions" section showing resize progress

# Check filesystem size inside pod (SSH into pod)
kubectl exec -it <pod> -- df -h
```

### Pod + Volume Mount
```bash
# Check volumes on pod
kubectl describe pod <pod> | grep -A 5 Volumes

# Check if PVC is mounted
kubectl get pod <pod> -o yaml | grep persistentVolumeClaim

# Write to volume inside pod
kubectl exec -it <pod> -- sh
echo "test data" > /data/file.txt

# Read from volume inside pod
kubectl exec -it <pod> -- cat /data/file.txt
```

---

## Security & RBAC

### ServiceAccount
```bash
# List service accounts
kubectl get sa
kubectl get sa -n <ns>

# Create service account
kubectl create serviceaccount <name> -n <ns>

# Get service account details
kubectl describe sa <name> -n <ns>

# View service account YAML (includes token secret)
kubectl get sa <name> -o yaml
```

### Role (Namespace-scoped)
```bash
# List roles
kubectl get role -n <ns>
kubectl describe role <name> -n <ns>

# Create role (imperative)
kubectl create role pod-reader --verb=get,list,watch --resource=pods -n <ns>

# Apply role from YAML
kubectl apply -f role.yaml

# View role YAML
kubectl get role <name> -o yaml
```

### RoleBinding (Namespace-scoped)
```bash
# List role bindings
kubectl get rolebinding -n <ns>

# Create role binding (imperative)
kubectl create rolebinding pod-reader-binding --role=pod-reader --serviceaccount=<ns>:default -n <ns>

# Apply role binding from YAML
kubectl apply -f rolebinding.yaml
```

### ClusterRole (Cluster-scoped)
```bash
# List cluster roles
kubectl get clusterrole

# Create cluster role
kubectl create clusterrole node-reader --verb=get,list --resource=nodes

# Apply cluster role from YAML
kubectl apply -f clusterrole.yaml
```

### ClusterRoleBinding (Cluster-scoped)
```bash
# List cluster role bindings
kubectl get clusterrolebinding

# Create cluster role binding
kubectl create clusterrolebinding node-reader-binding --clusterrole=node-reader --user=<username>

# Apply cluster role binding from YAML
kubectl apply -f clusterrolebinding.yaml
```

### RBAC Testing
```bash
# Can I perform an action? (current user)
kubectl auth can-i create pods -n <ns>
kubectl auth can-i delete deployments
kubectl auth can-i get secrets --all-namespaces

# Test as another user/service account
kubectl auth can-i get pods -n <ns> --as=system:serviceaccount:default:myuser

# List all permissions I have
kubectl auth can-i --list

# List all permissions for a service account
kubectl auth can-i --list --as=system:serviceaccount:default:myuser
```

### Secrets & ConfigMaps
```bash
# Create secret (generic key-value)
kubectl create secret generic <name> --from-literal=key=value -n <ns>

# Create secret from file
kubectl create secret generic <name> --from-file=config.json -n <ns>

# Create docker-registry secret
kubectl create secret docker-registry <name> \
  --docker-server=registry.example.com \
  --docker-username=user \
  --docker-password=pass

# List secrets
kubectl get secrets -n <ns>
kubectl describe secret <name> -n <ns>

# View secret data (base64 encoded)
kubectl get secret <name> -o yaml

# Decode secret (base64 decode)
kubectl get secret <name> -o jsonpath='{.data.key}' | base64 -d

# Create ConfigMap
kubectl create configmap <name> --from-literal=key=value -n <ns>

# List ConfigMaps
kubectl get configmaps -n <ns>
kubectl describe configmap <name> -n <ns>
```

### Pod Security & securityContext
```bash
# Pod security context (example YAML)
securityContext:
  runAsUser: 1000
  runAsNonRoot: true
  fsGroup: 2000
  readOnlyRootFilesystem: true

# Container security context (example YAML)
securityContext:
  allowPrivilegeEscalation: false
  capabilities:
    drop:
    - ALL

# Pod Security Admission (namespace labels)
kubectl label namespace <ns> pod-security.kubernetes.io/enforce=baseline

# Check Pod Security Admission labels on namespace
kubectl get ns <ns> --show-labels
```

---

## Troubleshooting

### General Diagnostic Sequence
```bash
# 1. Overview of resources
kubectl get all -n <ns>

# 2. Get detailed status (most important step!)
kubectl describe pod/<pod> -n <ns>

# 3. Check logs (current)
kubectl logs <pod> -n <ns>

# 4. Check logs if pod crashed/restarted
kubectl logs <pod> -n <ns> --previous

# 5. View recent events (sorted by time)
kubectl get events -n <ns> --sort-by=.metadata.creationTimestamp

# 6. Execute into pod for inspection
kubectl exec -it <pod> -n <ns> -- /bin/sh

# 7. Check node status (if scheduling issue)
kubectl describe node <node>

# 8. Check metrics (if resource issue, needs metrics-server)
kubectl top nodes
kubectl top pods -n <ns>
```

### Pod Troubleshooting
```bash
# Pod in CrashLoopBackOff
kubectl logs <pod> --previous  # See error before crash
kubectl describe pod <pod>  # Check exit code, reason

# Pod stuck Pending
kubectl describe pod <pod>  # Check events for reason
# Common causes: PVC pending, node selector not matching, resources insufficient

# Pod stuck Terminating
kubectl delete pod <pod> --grace-period=0 --force

# ImagePullBackOff
kubectl describe pod <pod>  # Check image name, registry
kubectl get secrets  # Check imagePullSecret

# Check pod restart count
kubectl get pods <pod> -o jsonpath='{.status.containerStatuses[0].restartCount}'
```

### Deployment Troubleshooting
```bash
# Deployment not scaling
kubectl describe deploy <name>  # Check replica status
kubectl get rs -l app=<label>  # Check ReplicaSets
kubectl get pods -l app=<label>  # Check pods

# Deployment not updating (image change stuck)
kubectl rollout status deployment/<name>  # Check progress
kubectl rollout history deployment/<name>  # Check revisions
kubectl get rs -l app=<label>  # Check old vs new ReplicaSets

# Deployment revision history not available
kubectl get rs  # View all ReplicaSets
# Note: revisionHistoryLimit controls how many old RS are kept (default=10)
```

### Service Troubleshooting
```bash
# Service not reachable
kubectl get svc <name>  # Check ports
kubectl get endpoints <name>  # Check if has endpoints
kubectl describe svc <name>  # Check selector labels

# Service endpoints empty
# → Check: Pod labels match service selector
# → Check: Pods are running
# → Check: Readiness probes passing

# DNS not resolving
kubectl run -it --image=dnsutils dnsutils --restart=Never -- bash
nslookup <service>.<namespace>.svc.cluster.local

# Check CoreDNS
kubectl get pods -n kube-system -l k8s-app=kube-dns
kubectl logs -n kube-system -l k8s-app=kube-dns
```

### Storage Troubleshooting
```bash
# PVC stuck Pending
kubectl describe pvc <pvc> -n <ns>  # Check events
# Common causes: storage class doesn't exist, provisioner not running, quota exceeded

# PV stuck Available (not binding to PVC)
kubectl describe pv <pv>  # Check status
# Check: accessModes match, capacity >= requested, storageClass matches

# Pod can't mount volume
kubectl describe pod <pod>  # Check mount events
# Check: PVC exists, PVC is Bound, mountPath correct

# Volume resize stuck
kubectl describe pvc <pvc>  # Check conditions
# Check: StorageClass has allowVolumeExpansion: true
# Check: New size > current size
```

### Node & Cluster Troubleshooting
```bash
# Node NotReady
kubectl describe node <node>  # Check conditions
kubectl logs -u kubelet -n <node>  # Check kubelet logs (SSH to node)

# Kubelet certificate expiry (control plane)
kubeadm certs check-expiration
kubeadm certs renew all

# API server not responding
kubectl cluster-info  # Check connection
kubectl get --raw /healthz  # Check API health

# etcd issues (control plane)
kubectl -n kube-system logs -l component=etcd

# Check resource metrics (HPA needs this)
kubectl get deployment metrics-server -n kube-system
kubectl top nodes
kubectl top pods
```

### RBAC & Access Troubleshooting
```bash
# Permission denied error
kubectl auth can-i <verb> <resource> -n <ns>  # Check permissions
kubectl get rolebinding -n <ns>  # List role bindings
kubectl describe rolebinding <name> -n <ns>

# ServiceAccount token not mounted
kubectl get sa <name> -n <ns> -o yaml  # Check automountServiceAccountToken

# User not found in kubeconfig
kubectl config view  # Check current context
kubectl config set-context --current --user=<user>

# kubeconfig connection issues
kubectl config view --minify  # Check context settings
kubectl cluster-info  # Verify API server is reachable
```

---

## Time-Saving Tips & Aliases

### Setup Quick Aliases (if allowed)
```bash
alias k=kubectl
alias kg='kubectl get'
alias kd='kubectl describe'
alias kl='kubectl logs'
alias ke='kubectl exec -it'
alias ka='kubectl apply'
alias kdel='kubectl delete'
```

### Common Shortcuts
```bash
# Get across all namespaces
k get <resource> -A

# Wide output (more detail)
k get <resource> -o wide

# YAML output
k get <resource> -o yaml

# JSON output (for jsonpath queries)
k get <resource> -o json

# Custom columns
k get pods --custom-columns=NAME:.metadata.name,IP:.status.podIP
```

---

## Quick Command Lookup by Problem Type

| Problem | Command |
|---------|---------|
| **"Show me deployment status"** | `kubectl describe deploy <name>` |
| **"Why is pod crashing?"** | `kubectl logs <pod> --previous` |
| **"Is service reachable?"** | `kubectl get endpoints <svc>` |
| **"PVC is stuck Pending"** | `kubectl describe pvc <pvc>` |
| **"Update image in deployment"** | `kubectl set image deploy/<name> app=new:tag` |
| **"Undo last deployment change"** | `kubectl rollout undo deploy/<name>` |
| **"Can user create pods?"** | `kubectl auth can-i create pods --as=<user>` |
| **"What happened in cluster?"** | `kubectl get events --sort-by=.metadata.creationTimestamp` |
| **"Fix pod stuck Terminating"** | `kubectl delete pod <pod> --grace-period=0 --force` |
| **"Check node resources"** | `kubectl top nodes` / `kubectl describe node <node>` |

---

**Need more detail?** Open `EXAM_QUICK_START.md` or specific domain folder `README.md`

**Memorize the top 20 commands first** — See `EXAM_MEMORIZATION_CHECKLIST.md`

