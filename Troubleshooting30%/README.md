## Troubleshooting & Debugging — Commands & YAML

Essential debugging commands and minimal debug-pod manifests for incident response.

Basic kubectl debugging
- Show recent events (sorted):
	```bash
	kubectl get events --sort-by=.metadata.creationTimestamp
	```
- Describe resources for detailed state and events:
	```bash
	kubectl describe pod <pod> -n <ns>
	kubectl describe node <node>
	```
- Tail logs from a pod (container):
	```bash
	kubectl logs -f <pod> -c <container> -n <ns>
	kubectl logs <pod> --previous
	```
- Exec into a running pod to inspect filesystem/network:
	```bash
	kubectl exec -it <pod> -n <ns> -- /bin/sh
	```

Debug pod examples
- Busybox debug pod (run, then exec):
	```bash
	kubectl run -i --tty debug --image=busybox --restart=Never --rm -- sh
	```
- Ephemeral debug container (kubectl alpha debugging if available):
	```bash
	kubectl debug -it node/<node-name> --image=busybox --target=<pod-name>
	```

Node-level checks
- Kubelet logs on node:
	```bash
	sudo journalctl -u kubelet -n 200
	```
- Check systemctl services:
	```bash
	systemctl status kubelet
	systemctl status docker # or containerd
	```

API & control-plane checks
- See control plane pod status:
	```bash
	kubectl -n kube-system get pods -o wide
	kubectl -n kube-system logs -l component=kube-apiserver
	```
- API health endpoints:
	```bash
	kubectl get --raw /healthz
	kubectl get --raw /readyz
	```

Quick troubleshooting tips
- If pods are ImagePullBackOff: check `kubectl describe pod` for image and pull error and `kubectl get events`.
- CrashLoopBackOff: use `kubectl logs --previous` and `kubectl describe pod` to get the exit reason and backoff.
- Networking issues: run a DNS/utility pod and use `nslookup`, `ping`, `curl` between pods.

Keep this README as the go-to place for pasteable debug commands and small debug pod manifests.
