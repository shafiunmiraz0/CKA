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

Extra quick troubleshooting commands
- `kubectl get events -A --sort-by=.metadata.creationTimestamp` — show recent events cluster-wide
- `kubectl get all -n <ns>` — quick snapshot of namespace resources
- `kubectl logs -f <pod> -c <container> --since=1h` — tail logs from the last hour
- `kubectl cp <pod>:/path/file ./localfile -n <ns>` — copy files from pod to local filesystem
- `kubectl auth can-i create pods -n <ns>` — verify permissions quickly

Added snippet references
- `../snippets/dnsutils-debug.yaml` — dnsutils pod for DNS troubleshooting
- `../snippets/busybox-debug.yaml` — BusyBox debug pod for quick execs

Snippets
- Useful debug and support snippets are available in `../snippets/` (relative to this README):
	- `../snippets/initcontainers.yaml` (initContainers example)
	- `../snippets/job.yaml` (Job example)
	- `../snippets/cronjob.yaml` (CronJob example)
		- `../snippets/snippets-README.md` (index of all snippets)

Security commands & snippets
- Security-focused troubleshooting commands:
	- `kubectl auth can-i --list --all-namespaces` — list actions the current user can perform
	- `kubectl get events -A --sort-by=.metadata.creationTimestamp` — spot security-related failures (imagepull, secrets)
	- `kubectl get podsecuritypolicy` — PSP is deprecated; prefer Pod Security Admission namespace labels (see snippets)
- Useful snippets for debugging security posture:
	- Pod Security Admission labels: `../snippets/podsecurity-namespace-labels.yaml`
	- seccomp/apparmor examples to test runtime enforcement: `../snippets/seccomp-pod.yaml`, `../snippets/apparmor-pod.yaml`

CKA 1.34 / Debug & admin commands
- Cluster dump for debugging (control-plane & events):
	- `kubectl cluster-info dump --output-directory=./cluster-dump`
- Metrics & resource troubleshooting:
	- `kubectl top nodes`
	- `kubectl top pods -n <ns>`
	- `kubectl describe node <node>` (look for scheduling, pressure conditions)
- Ephemeral debugging and injection:
	- `kubectl debug -it pod/<pod> --image=busybox --target=<container>`

Observability & logging commands
- If metrics-server is installed, get resource metrics:
	- `kubectl top nodes`
	- `kubectl top pods -n <ns>`
- Prometheus quick checks (if installed):
	- Port-forward Prometheus UI: `kubectl port-forward -n monitoring svc/prometheus 9090:9090`
	- Check scrape targets via the Prometheus UI (Targets page)
- Logging DaemonSet checks (Fluent Bit/Fluentd):
	- `kubectl get daemonset -n kube-logging`
	- `kubectl logs -n kube-logging <fluent-bit-pod>`
	- `kubectl describe daemonset fluent-bit -n kube-logging`

