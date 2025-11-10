# Pod + Service (Advanced)

## Purpose
Advanced patterns for Pod-Service integrations, headless services, multi-port services, readiness/liveness interplay.

## Headless Service + StatefulSet (recap)
```yaml
apiVersion: v1
kind: Service
metadata:
  name: db-headless
spec:
  clusterIP: None
  selector:
    app: db
  ports:
  - port: 27017
    name: mongo
```

## Multi-port Service example
```yaml
apiVersion: v1
kind: Service
metadata:
  name: multiport
spec:
  selector:
    app: myapp
  ports:
  - name: http
    port: 80
    targetPort: 8080
  - name: metrics
    port: 9100
    targetPort: 9100
```

## Readiness vs Liveness probes
```yaml
livenessProbe:
  httpGet:
    path: /healthz
    port: 8080
  initialDelaySeconds: 15
  periodSeconds: 20
readinessProbe:
  httpGet:
    path: /ready
    port: 8080
  initialDelaySeconds: 5
  periodSeconds: 10
```

## DNS and Service discovery troubleshooting
- Use a debugging pod (busybox/netshoot) to run `nslookup`, `dig`, `wget`.
- If service has no endpoints: check pod labels and `kubectl get endpoints <svc>`.
- If DNS resolves but connection fails: check NetworkPolicies, service ports, and targetPort alignment.

## Test commands
```bash
# DNS test
kubectl run -it --rm dns-test --image=busybox -- nslookup myservice

# HTTP test
kubectl run -it --rm client --image=busybox -- wget -qO- http://myservice:80

# Inspect endpoints
kubectl get endpoints myservice -o yaml
```

## Exam tips
- Prefere headless services for StatefulSets; validate endpoints after creating pods.
- Use readiness probes to prevent traffic to unready pods during rolling updates.
- Test multi-port services by specifying the port name or number.
