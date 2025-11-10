## Workloads & Scheduling — Commands & YAML

Common workload types, scheduling, taints/tolerations, and small YAML examples to copy.

Deployments
```yaml
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
```
Commands
- Apply a deployment: `kubectl apply -f deployment.yaml`
- Scale: `kubectl scale deployment/nginx --replicas=5`
- Rollout status and undo:
	```bash
	kubectl rollout status deployment/nginx
	kubectl rollout undo deployment/nginx
	```

DaemonSet (minimal)
```yaml
apiVersion: apps/v1
kind: DaemonSet
metadata:
	name: ds
spec:
	selector:
		matchLabels:
			name: ds
	template:
		metadata:
			labels:
				name: ds
		spec:
			containers:
			- name: pause
				image: k8s.gcr.io/pause:3.5
```

StatefulSet and Jobs
- StatefulSet (useful when stable network id / storage needed).
- Job/CronJob examples are useful for one-off tasks and scheduled tasks:
	```yaml
	apiVersion: batch/v1
	kind: Job
	metadata:
		name: pi-job
	spec:
		template:
			spec:
				containers:
				- name: pi
					image: perl
					command: ["perl","-Mbignum=bpi","-wle","print bpi(2000)"]
				restartPolicy: Never
	```

Scheduling primitives
- Node selectors: `nodeSelector:` in pod spec (simple key:value)
- Affinity/Anti-affinity: use `affinity:` with `nodeAffinity` and `podAffinity` in pod spec
- Taints & tolerations:
	```bash
	kubectl taint nodes <node> key=value:NoSchedule
	# remove taint
	kubectl taint nodes <node> key:NoSchedule-
	```

Notes
- Practice converting requirements into pod spec fields quickly (resources, nodeSelector, tolerations, affinity).
- Keep small YAML snippets (Deployments, DaemonSets, StatefulSets, Jobs) on your permitted GitHub tab for quick reuse during the exam.

Snippets
- A larger set of exam-style snippets and per-resource YAML lives in the `snippets/` folder (relative to this README):
	- `../snippets/deployment.yaml` (Deployment example)
	- `../snippets/daemonset.yaml` (DaemonSet example)
	- `../snippets/statefulset.yaml` (StatefulSet + PVC template)
	- `../snippets/job.yaml` and `../snippets/cronjob.yaml` (batch examples)
	- `../snippets/hpa.yaml` (HPA example)
	- `../snippets/rbac-role-sa.yaml` (RBAC example)
	- `../snippets/configmap-secret.yaml` (ConfigMap/Secret examples)
	- `../snippets/initcontainers.yaml` (initContainers example)
	- `../snippets/resourcequota-limitrange.yaml` (ResourceQuota / LimitRange)
	- `../snippets/snippets-README.md` (index of all snippets)

	CKA 1.34 / Workloads & scheduling commands
	- Scheduling and priority commands:
		- Create/inspect PriorityClasses: `kubectl get priorityclass` and `kubectl apply -f ../snippets/priorityclass.yaml`
		- Preemption/priority debugging: check `kubectl describe pod <pod>` for preemption events
	- Probes & lifecycle checks:
		- Use `kubectl describe pod <pod>` and `kubectl logs <pod>` to diagnose readiness/liveness failures; sample probes in `../snippets/liveness-readiness.yaml`
	- RuntimeClass usage:
		- Apply `RuntimeClass` and reference it in pod spec: `runtimeClassName: kata-runtime` (see `../snippets/runtimeclass.yaml`)

	Observability snippets & checks
	- Ensure metrics-server is running for HPA and `kubectl top`: `../snippets/metrics-server.yaml`
	- Use Prometheus basic example to validate scraping and metrics: `../snippets/prometheus-basic.yaml`
	- Use Fluent Bit DaemonSet for basic log collection: `../snippets/fluentbit-daemonset.yaml`

