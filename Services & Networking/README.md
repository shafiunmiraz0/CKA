## Services & Networking — Commands & YAML

Service types, networking checks, Ingress and NetworkPolicy snippets and quick DNS tests.

Useful kubectl/networking commands
- Expose a deployment as ClusterIP (internal):
	```bash
	kubectl expose deployment/nginx --port=80 --target-port=80 --name=nginx-svc
	```
- Expose as NodePort:
	```bash
	kubectl expose deployment/nginx --type=NodePort --port=80
	```
- Expose as LoadBalancer (cloud):
	```bash
	kubectl expose deployment/nginx --type=LoadBalancer --port=80
	```
- Check endpoints for a Service:
	```bash
	kubectl get endpoints nginx-svc
	```
- Port forward a service for testing:
	```bash
	kubectl port-forward svc/my-svc 8080:80
	```

DNS and connectivity tests
- Start a debug pod to test cluster DNS and connectivity:
	```bash
	kubectl run -i --tty dnsutils --image=tianon/dnsutils --restart=Never --rm -- bash -il
	# inside: nslookup kubernetes.default
	```

Ingress (minimal example)
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
	name: example-ingress
spec:
	rules:
	- host: example.local
		http:
			paths:
			- path: /
				pathType: Prefix
				backend:
					service:
						name: nginx-svc
						port:
							number: 80
```

NetworkPolicy (deny by default to/from example)
```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
	name: deny-all
	namespace: default
spec:
	podSelector: {}
	policyTypes:
	- Ingress
	- Egress
```

Notes
- CNI plugins implement pod networking (Flannel, Calico, Weave). If pods are NotReady or NotRunning after init, check CNI installation (`kubectl -n kube-system get pods`).
- For kube-proxy checks: `kubectl -n kube-system get pods -l k8s-app=kube-proxy` and `kubectl -n kube-system describe daemonset kube-proxy`.

Snippets
- Relevant YAML snippets for networking are in `../snippets/` (relative to this README):
		- `../snippets/snippets-README.md` (index of all snippets)
		- `../snippets/ingress-tls.yaml` (Ingress with TLS example)
		- `../snippets/networkpolicy-deny-allow.yaml` (NetworkPolicy example)
		- `../snippets/configmap-secret.yaml` (ConfigMap/Secret examples)

Security commands & snippets
- Quick security/network checks:
	- `kubectl get networkpolicy -n <ns>` — view network policies in a namespace
	- `kubectl describe networkpolicy <name> -n <ns>` — inspect rules
	- Use a debug pod to test connectivity: `kubectl run -i --tty dnsutils --image=tianon/dnsutils --restart=Never --rm -- bash -il`
- Useful snippets:
	- Restrictive NetworkPolicy example: `../snippets/networkpolicy-restrict-egress.yaml`
	- Pod Security Admission labels: `../snippets/podsecurity-namespace-labels.yaml`

CKA 1.34 / Networking & admin commands
- Inspect API resources / services:
	- `kubectl api-resources`
	- `kubectl get endpointslice -A` (if EndpointSlice feature in use)
	- `kubectl get svc -A` / `kubectl get ep -A`
- Debugging network stack from node and control plane:
	- `kubectl cluster-info dump --namespaces=kube-system` to inspect controller logs and kube-proxy state
	- Use `kubectl port-forward` for local access to services: `kubectl port-forward svc/my-svc 8080:80`

Observability & logging (snippets + commands)
- Install metrics-server for `kubectl top` and cluster metrics: see `../snippets/metrics-server.yaml`.
- Prometheus basic test deployment and port-forward: `../snippets/prometheus-basic.yaml` then `kubectl port-forward -n monitoring svc/prometheus 9090:9090`.
- Check endpoints / targets in Prometheus UI and `kubectl get servicemonitor -A` if using the operator.
- Fluent Bit/Fluentd logging DaemonSet example: `../snippets/fluentbit-daemonset.yaml`. Check logs with `kubectl logs -n kube-logging daemonset/fluent-bit` or pod logs if DaemonSet created pods.

More quick kubectl/networking commands
- `kubectl describe svc <svc> -n <ns>` — inspect service selectors and ports
- `kubectl get endpointslices -n <ns>` — check EndpointSlice objects for services
- `kubectl proxy --port=8001` — access the API locally via proxy for ad-hoc requests
- `kubectl port-forward <pod|svc> 8080:80 -n <ns>` — forward ports for testing
- `kubectl apply -f ../snippets/networkpolicy-allow-dns.yaml` — apply DNS-allow NetworkPolicy snippet

Added snippet references
- `../snippets/networkpolicy-allow-dns.yaml` — allow DNS egress policy example
- `../snippets/ingress-basic.yaml` — simple ingress example for testing

