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

