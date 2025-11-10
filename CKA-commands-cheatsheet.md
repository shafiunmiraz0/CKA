## CKA Commands Cheat Sheet

This file collects concise kubectl, kubeadm, and YAML snippets organized by typical CKA topics. Use it as a single-page quick reference during practice. The CKA exam allows two browser tabs: one for https://kubernetes.io and one for GitHub — keep those open for api/docs and YAML snippets.

### Global kubectl tips
- Default namespace: `kubectl config set-context --current --namespace=<ns>`
- Show all resources: `kubectl api-resources`
- Quick context/cluster info: `kubectl config view --minify`, `kubectl config current-context`
- Useful flags: `-n <ns>`, `-o wide`, `-o yaml`, `-o jsonpath='{...}'`

### Common kubectl commands
- Get resources: `kubectl get pods`, `kubectl get svc,ep,ingress`, `kubectl get nodes`
- Describe: `kubectl describe pod/<name>`
- Logs: `kubectl logs <pod> [-c <container>] [--since=1m]` or for previous: `--previous`
- Exec: `kubectl exec -it <pod> -- /bin/sh` or `-- /bin/bash`
- Apply manifest: `kubectl apply -f <file|dir>`
- Create from file: `kubectl create -f <file>`
- Edit live resource: `kubectl edit <resource>/<name>`
- Port forward: `kubectl port-forward svc/<svc> 8080:80` or `kubectl port-forward pod/<pod> 8080:80`
- Copy files: `kubectl cp localfile <pod>:/path` and reverse
- Scale: `kubectl scale deployment/<name> --replicas=3`
- Rollouts: `kubectl rollout status deployment/<name>`, `kubectl rollout undo deployment/<name>`
- Replace vs apply: `kubectl replace --force -f <file>` (force replace)

### YAML output & selection examples
- Show pod YAML: `kubectl get pod <p> -o yaml`
- Get images used: `kubectl get pods -o jsonpath='{range .items[*]}{.metadata.name} {.spec.containers[*].image}\n{end}'`

### Cluster Architecture / Installation (kubeadm)
- Initialize control plane (single node):
  `kubeadm init --pod-network-cidr=10.244.0.0/16`
  (save the kubeadm join command printed)
- Join worker to cluster (copy from control plane):
  `kubeadm join <control-plane-ip>:6443 --token <token> --discovery-token-ca-cert-hash sha256:<hash>`
- View kubelet service: `systemctl status kubelet`
- Static manifests: check `/etc/kubernetes/manifests/` on control plane
- Reset a node: `kubeadm reset -f` and optionally remove CNI config, iptables rules, `/etc/cni/net.d` and kube configs

### Networking & Services
- Expose a deployment as ClusterIP: `kubectl expose deployment nginx --port=80 --target-port=80 --name=nginx-svc`
- NodePort: `kubectl expose deployment nginx --type=NodePort --port=80`
- LoadBalancer (cloud): `kubectl expose deployment nginx --type=LoadBalancer --port=80`
- Check endpoints: `kubectl get endpoints <svc>`
- Port-forwarding for testing: `kubectl port-forward svc/my-svc 8080:80`
- Test DNS: `kubectl run -i --tty dnsutils --image=tianon/dnsutils --restart=Never --rm -- bash -il`
  then `nslookup kubernetes.default` or `dig svcname.namespace.svc.cluster.local`
- NetworkPolicy basics: `kubectl apply -f networkpolicy.yaml` (default allow, use policies to restrict)

### Storage (PVs, PVCs, StorageClass)
- Create PVC: `kubectl apply -f pvc.yaml`
- Show PV/PVC: `kubectl get pv`, `kubectl get pvc -n <ns>`
- Inspect PV: `kubectl describe pv <pv-name>`
- Example PVC snippet (dynamic provisioning):
  apiVersion: v1
  kind: PersistentVolumeClaim
  metadata:
    name: mypvc
  spec:
    accessModes: ["ReadWriteOnce"]
    resources:
      requests:
        storage: 1Gi
    storageClassName: standard

- For hostPath (not for production, useful in labs):
  apiVersion: v1
  kind: PersistentVolume
  metadata:
    name: pv-hostpath
  spec:
    capacity:
      storage: 1Gi
    accessModes:
      - ReadWriteOnce
    hostPath:
      path: /mnt/data

### Workloads & Scheduling
- Deployments: `kubectl apply -f deployment.yaml`
- DaemonSets: `kubectl apply -f daemonset.yaml`
- StatefulSets: `kubectl apply -f statefulset.yaml`
- Jobs / CronJobs: `kubectl create job --from=cronjob/<cj> <job-name>`; `kubectl get jobs` / `kubectl get cronjobs`
- Affinity/Anti-affinity and Node selectors: use `nodeSelector`, `affinity` in pod spec
- Taints & tolerations: `kubectl taint nodes <node> key=value:NoSchedule-` (use `-` to remove)
- Evict a pod: `kubectl delete pod <pod> --grace-period=0 --force` (use carefully)

### Resource requests and limits
- Example container resources:
  resources:
    requests:
      cpu: "100m"
      memory: "128Mi"
    limits:
      cpu: "500m"
      memory: "256Mi"

### Troubleshooting & Debugging
- Events: `kubectl get events --sort-by=.metadata.creationTimestamp`
- Describe failing resource: `kubectl describe pod <pod>` or `kubectl describe node <node>`
- Check pod status and reason: `kubectl get pod <p> -o yaml` (look at .status)
- Check kubelet logs (on node): `journalctl -u kubelet -l` or `sudo journalctl -u kubelet -n 200`
- Check control plane pods: `kubectl -n kube-system get pods -o wide`
- Check API server: `kubectl get --raw /healthz` or use `kubectl cluster-info` and `kubectl get componentstatuses`
- Debugging a pod: `kubectl run -i --tty debug --image=busybox --restart=Never -- sh` then nslookup/curl inside cluster

### Misc useful commands
- Delete all resources in namespace: `kubectl delete all --all -n <ns>`
- Label / annotate resources: `kubectl label node <node> rack=1`, `kubectl annotate pod <pod> owner=me`
- Patch example: `kubectl patch deployment mydep -p '{"spec":{"replicas":2}}'`
- Grep resource on cluster: `kubectl get pods --all-namespaces -o custom-columns=NAMESPACE:.metadata.namespace,NAME:.metadata.name | grep <term>`

### Quick YAML templates (minimal)
- Deployment (minimal):
  apiVersion: apps/v1
  kind: Deployment
  metadata:
    name: nginx
  spec:
    replicas: 2
    selector:
      matchLabels:
        app: nginx
    template:
      metadata:
        labels:
          app: nginx
      spec:
        containers:
        - name: nginx
          image: nginx:1.21
          ports:
          - containerPort: 80

### Exam tips
- The exam allows 2 browser tabs: one for kubernetes.io and one for GitHub. Keep direct links to API references and common manifests on GitHub (e.g., your personal repo or a public snippet repo) for quick copy-paste.
- Practice with time pressure. The exam expects fast, correct kubectl usage and YAML editing.
- Save frequently used YAML snippets in a GitHub repo (allowed tab) for quick reuse (Deployments, Services, PVCs, NetworkPolicy, Pod debug manifests).

---
End of cheat sheet — update and expand with your own shortcuts and YAML snippets.
