## Cluster Architecture, Installation & Configuration — Commands & YAML

Quick control-plane and node operations, kubeadm examples, and places to check on the node.

Important commands
- Initialize control plane (single control-plane, example with Flannel/CNI range):
	```bash
	kubeadm init --pod-network-cidr=10.244.0.0/16
	```
- Save the `kubeadm join ...` command printed by `kubeadm init` and run on workers.
- List tokens (to get a join token):
	```bash
	kubeadm token list
	```
- Create a new token: `kubeadm token create --print-join-command`
- Join worker to cluster (example):
	```bash
	kubeadm join <control-plane-ip>:6443 --token <token> --discovery-token-ca-cert-hash sha256:<hash>
	```

Node / service checks
- Check kubelet status on node:
	```bash
	systemctl status kubelet
	sudo journalctl -u kubelet -n 200
	```
- Static control plane manifests live in `/etc/kubernetes/manifests/` on control plane nodes.

Reset and cleanup
- Reset kubeadm on a node (be careful — this removes cluster configuration):
	```bash
	kubeadm reset -f
	# Remove CNI state if needed:
	sudo rm -rf /etc/cni/net.d
	sudo iptables -F
	```

Control-plane troubleshooting
- Check kube-system pods and API reachability:
	```bash
	kubectl -n kube-system get pods -o wide
	kubectl cluster-info
	kubectl get --raw /healthz
	```

Minimal kubeadm config snippet (example for advanced init)
```yaml
apiVersion: kubeadm.k8s.io/v1beta3
kind: ClusterConfiguration
kubernetesVersion: stable
networking:
	podSubnet: "10.244.0.0/16"
controlPlaneEndpoint: "LOADBALANCER:6443" # optional for HA setups
```

Notes
- After `kubeadm init` you must set up the kubeconfig for regular user (example):
	```bash
	mkdir -p $HOME/.kube
	sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
	sudo chown $(id -u):$(id -g) $HOME/.kube/config
	```

Keep this README as a quick paste source for kubeadm and node-level commands during practice.

Snippets
- You can find ready-to-use YAML snippets in the repository `snippets/` folder (relative path from this file):
	- `../snippets/pv-hostpath.yaml` (hostPath PV)
	- `../snippets/storageclass.yaml` (StorageClass example)
	- `../snippets/rbac-role-sa.yaml` (ServiceAccount / Role / RoleBinding)
	- `../snippets/configmap-secret.yaml` (ConfigMap and Secret examples)
		- `../snippets/snippets-README.md` (index of all snippets)

Security commands & snippets
- Quick security checks:
	- `kubectl auth can-i <verb> <resource> -n <ns>` — test RBAC for current user
	- `kubectl get networkpolicy -A` — list NetworkPolicy objects
	- `kubectl get secrets -n kube-system` — check secrets in control plane namespace
- Useful snippets (see `../snippets/snippets-README.md`):
	- Pod Security Admission namespace labels: `../snippets/podsecurity-namespace-labels.yaml`
	- seccomp & AppArmor pod examples: `../snippets/seccomp-pod.yaml`, `../snippets/apparmor-pod.yaml`
	- imagePullSecret template: `../snippets/imagepullsecret.yaml`

CKA 1.34 / Admin commands
- Maintenance & admin commands cheat sheet: `../snippets/cluster-maintenance-commands.md`
- Scheduling / maintenance examples:
	- `kubectl cordon <node>`
	- `kubectl drain <node> --ignore-daemonsets --delete-local-data`
	- `kubectl uncordon <node>`
	- `kubeadm certs check-expiration`
	- `kubeadm certs renew all`

Observability & monitoring
- Install and check metrics-server for resource metrics (used by HPA and `kubectl top`): `../snippets/metrics-server.yaml`
- Basic Prometheus for scraping and debugging: `../snippets/prometheus-basic.yaml` (namespace `monitoring`)
- Logging DaemonSet sample (Fluent Bit): `../snippets/fluentbit-daemonset.yaml`

More admin & troubleshooting commands
- `kubectl get all -A` — quick view of cluster resources across namespaces
- `kubectl get componentstatuses` — check core component statuses (deprecated on some clusters)
- `kubectl api-resources` / `kubectl api-versions` — discover resources available in the cluster
- `kubectl auth can-i <verb> <resource> -n <ns>` — test RBAC for current user
- `kubectl cluster-info dump --output-directory=./cluster-dump` — collect cluster debug info

Added snippet references
- `../snippets/rbac-clusterrolebinding.yaml` — example ClusterRole and ClusterRoleBinding for debug access
- `../snippets/secret-tls.yaml` — TLS secret example

