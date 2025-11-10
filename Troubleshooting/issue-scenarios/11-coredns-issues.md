# Scenario: CoreDNS failures / DNS resolution issues

Symptom
- DNS lookups fail in pods; `nslookup kubernetes.default` times out; CoreDNS pods CrashLoopBackOff or NotReady.

Quick diagnostics
- kubectl -n kube-system get pods -l k8s-app=kube-dns
- kubectl logs -n kube-system <coredns-pod>
- kubectl exec -it <pod> -- nslookup kubernetes.default || true

Common causes & fixes

1) CoreDNS pods not running or CrashLoopBackOff

Fix: `kubectl describe pod` for CoreDNS, check configmap `coredns` in `kube-system`, restart pods: `kubectl rollout restart deployment/coredns -n kube-system`.

2) ConfigMap misconfiguration (Corefile errors)

Fix: inspect `kubectl -n kube-system get configmap coredns -o yaml` and validate Corefile syntax. Apply a corrected ConfigMap and restart pods.

3) NetworkPolicy blocking DNS

If restrictive NetworkPolicy applied, ensure pods can reach DNS port 53. Apply the `networkpolicy-allow-dns.yaml` snippet to test.

Exam tip
- Use a debug pod (`kubectl run -i --tty dnsutils --image=tianon/dnsutils --restart=Never --rm -- bash`) to test cluster DNS from inside the network.
