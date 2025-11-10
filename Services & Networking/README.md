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

# Services & Networking (20%)## Services & Networking — Commands & YAML



## Core ConceptsService types, networking checks, Ingress and NetworkPolicy snippets and quick DNS tests.



### 1. Service TypesUseful kubectl/networking commands

- [ClusterIP](scenarios/clusterip/README.md)- Expose a deployment as ClusterIP (internal):

- [NodePort](scenarios/nodeport/README.md)	```bash

- [LoadBalancer](scenarios/loadbalancer/README.md)	kubectl expose deployment/nginx --port=80 --target-port=80 --name=nginx-svc

- [ExternalName](scenarios/externalname/README.md)	```

- Expose as NodePort:

### 2. DNS and Service Discovery	```bash

- [CoreDNS Configuration](scenarios/coredns/README.md)	kubectl expose deployment/nginx --type=NodePort --port=80

- [DNS Debugging](scenarios/dns-debugging/README.md)	```

- [Service Discovery](scenarios/service-discovery/README.md)- Expose as LoadBalancer (cloud):

	```bash

### 3. Ingress	kubectl expose deployment/nginx --type=LoadBalancer --port=80

- [Ingress Controllers](scenarios/ingress/README.md)	```

- [Ingress Rules](scenarios/ingress-rules/README.md)- Check endpoints for a Service:

- [TLS Configuration](scenarios/ingress-tls/README.md)	```bash

	kubectl get endpoints nginx-svc

### 4. Network Policies	```

- [Network Policy Basics](scenarios/network-policy/README.md)- Port forward a service for testing:

- [Ingress/Egress Rules](scenarios/network-policy-rules/README.md)	```bash

	kubectl port-forward svc/my-svc 8080:80

## Common Commands	```



### Service ManagementDNS and connectivity tests

```bash- Start a debug pod to test cluster DNS and connectivity:

# Create a service	```bash

kubectl expose deployment nginx --port=80 --type=ClusterIP	kubectl run -i --tty dnsutils --image=tianon/dnsutils --restart=Never --rm -- bash -il

kubectl expose deployment nginx --port=80 --type=NodePort	# inside: nslookup kubernetes.default

kubectl expose deployment nginx --port=80 --type=LoadBalancer	```



# List and describe servicesIngress (minimal example)

kubectl get services```yaml

kubectl describe service nginxapiVersion: networking.k8s.io/v1

kind: Ingress

# Delete servicemetadata:

kubectl delete service nginx	name: example-ingress

```spec:

	rules:

### DNS Operations	- host: example.local

```bash		http:

# DNS debugging			paths:

kubectl run dnsutils --image=tutum/dnsutils --command -- sleep infinity			- path: /

kubectl exec -it dnsutils -- nslookup kubernetes.default				pathType: Prefix

kubectl exec -it dnsutils -- nslookup <service-name>				backend:

					service:

# Check CoreDNS						name: nginx-svc

kubectl get pods -n kube-system -l k8s-app=kube-dns						port:

kubectl logs -n kube-system -l k8s-app=kube-dns							number: 80

``````



### Network PolicyNetworkPolicy (deny by default to/from example)

```bash```yaml

# List network policiesapiVersion: networking.k8s.io/v1

kubectl get networkpolicieskind: NetworkPolicy

kubectl get netpolmetadata:

	name: deny-all

# Describe network policy	namespace: default

kubectl describe networkpolicy my-policyspec:

```	podSelector: {}

	policyTypes:

### Ingress Operations	- Ingress

```bash	- Egress

# List and describe ingress```

kubectl get ingress

kubectl describe ingress my-ingressNotes

- CNI plugins implement pod networking (Flannel, Calico, Weave). If pods are NotReady or NotRunning after init, check CNI installation (`kubectl -n kube-system get pods`).

# Get ingress controller pods- For kube-proxy checks: `kubectl -n kube-system get pods -l k8s-app=kube-proxy` and `kubectl -n kube-system describe daemonset kube-proxy`.

kubectl get pods -n ingress-nginx

```Snippets

- Relevant YAML snippets for networking are in `../snippets/` (relative to this README):

## YAML Templates		- `../snippets/snippets-README.md` (index of all snippets)

		- `../snippets/ingress-tls.yaml` (Ingress with TLS example)

### Basic Service		- `../snippets/networkpolicy-deny-allow.yaml` (NetworkPolicy example)

```yaml		- `../snippets/configmap-secret.yaml` (ConfigMap/Secret examples)

apiVersion: v1

kind: ServiceSecurity commands & snippets

metadata:- Quick security/network checks:

  name: my-service	- `kubectl get networkpolicy -n <ns>` — view network policies in a namespace

spec:	- `kubectl describe networkpolicy <name> -n <ns>` — inspect rules

  selector:	- Use a debug pod to test connectivity: `kubectl run -i --tty dnsutils --image=tianon/dnsutils --restart=Never --rm -- bash -il`

	app: my-app- Useful snippets:

  ports:	- Restrictive NetworkPolicy example: `../snippets/networkpolicy-restrict-egress.yaml`

	- protocol: TCP	- Pod Security Admission labels: `../snippets/podsecurity-namespace-labels.yaml`

	  port: 80

	  targetPort: 8080CKA 1.34 / Networking & admin commands

  type: ClusterIP- Inspect API resources / services:

```	- `kubectl api-resources`

	- `kubectl get endpointslice -A` (if EndpointSlice feature in use)

### Network Policy	- `kubectl get svc -A` / `kubectl get ep -A`

```yaml- Debugging network stack from node and control plane:

apiVersion: networking.k8s.io/v1	- `kubectl cluster-info dump --namespaces=kube-system` to inspect controller logs and kube-proxy state

kind: NetworkPolicy	- Use `kubectl port-forward` for local access to services: `kubectl port-forward svc/my-svc 8080:80`

metadata:

  name: default-deny-ingressObservability & logging (snippets + commands)

spec:- Install metrics-server for `kubectl top` and cluster metrics: see `../snippets/metrics-server.yaml`.

  podSelector: {}- Prometheus basic test deployment and port-forward: `../snippets/prometheus-basic.yaml` then `kubectl port-forward -n monitoring svc/prometheus 9090:9090`.

  policyTypes:- Check endpoints / targets in Prometheus UI and `kubectl get servicemonitor -A` if using the operator.

  - Ingress- Fluent Bit/Fluentd logging DaemonSet example: `../snippets/fluentbit-daemonset.yaml`. Check logs with `kubectl logs -n kube-logging daemonset/fluent-bit` or pod logs if DaemonSet created pods.

```

More quick kubectl/networking commands

### Basic Ingress- `kubectl describe svc <svc> -n <ns>` — inspect service selectors and ports

```yaml- `kubectl get endpointslices -n <ns>` — check EndpointSlice objects for services

apiVersion: networking.k8s.io/v1- `kubectl proxy --port=8001` — access the API locally via proxy for ad-hoc requests

kind: Ingress- `kubectl port-forward <pod|svc> 8080:80 -n <ns>` — forward ports for testing

metadata:- `kubectl apply -f ../snippets/networkpolicy-allow-dns.yaml` — apply DNS-allow NetworkPolicy snippet

  name: minimal-ingress

spec:Added snippet references

  rules:- `../snippets/networkpolicy-allow-dns.yaml` — allow DNS egress policy example

  - http:- `../snippets/ingress-basic.yaml` — simple ingress example for testing

	  paths:

	  - path: /
		pathType: Prefix
		backend:
		  service:
			name: my-service
			port:
			  number: 80
```

## Important Notes

1. Service Types:
   - ClusterIP: Internal cluster communication
   - NodePort: External access via node ports
   - LoadBalancer: External access via cloud provider
   - ExternalName: DNS CNAME record

2. Network Policy Best Practices:
   - Start with deny-all policy
   - Add specific allow rules
   - Test thoroughly
   - Document all policies

3. Ingress Considerations:
   - Install ingress controller first
   - Configure TLS properly
   - Set up default backend
   - Monitor ingress controller logs

4. Troubleshooting Tips:
   - Use kubectl describe for detailed info
   - Check service endpoints
   - Verify network policy conflicts
   - Monitor ingress controller logs
   - Use DNS debugging tools