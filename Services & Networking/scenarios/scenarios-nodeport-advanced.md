# Advanced NodePort Scenarios

## Scenario 1: High Availability NodePort
Task: Create NodePort service with multiple replicas

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: ha-web
spec:
  replicas: 3
  selector:
    matchLabels:
      app: ha-web
  template:
    metadata:
      labels:
        app: ha-web
    spec:
      containers:
      - name: nginx
        image: nginx:1.21
        ports:
        - containerPort: 80
---
apiVersion: v1
kind: Service
metadata:
  name: ha-nodeport
spec:
  type: NodePort
  selector:
    app: ha-web
  ports:
    - port: 80
      targetPort: 80
      nodePort: 30080
```

## Scenario 2: NodePort with Health Checks
Task: Configure readiness and liveness probes

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web-health
spec:
  replicas: 2
  selector:
    matchLabels:
      app: web-health
  template:
    metadata:
      labels:
        app: web-health
    spec:
      containers:
      - name: nginx
        image: nginx:1.21
        ports:
        - containerPort: 80
        livenessProbe:
          httpGet:
            path: /
            port: 80
          initialDelaySeconds: 3
          periodSeconds: 3
        readinessProbe:
          httpGet:
            path: /
            port: 80
          initialDelaySeconds: 3
          periodSeconds: 3
---
apiVersion: v1
kind: Service
metadata:
  name: health-nodeport
spec:
  type: NodePort
  selector:
    app: web-health
  ports:
    - port: 80
      targetPort: 80
```

## Scenario 3: Session Affinity
Task: Configure session affinity for NodePort

```yaml
apiVersion: v1
kind: Service
metadata:
  name: sticky-nodeport
spec:
  type: NodePort
  sessionAffinity: ClientIP
  sessionAffinityConfig:
    clientIP:
      timeoutSeconds: 10800
  selector:
    app: web
  ports:
    - port: 80
      targetPort: 8080
```

## Scenario 4: NodePort with External Traffic Policy
Task: Configure local traffic policy

```yaml
apiVersion: v1
kind: Service
metadata:
  name: local-traffic-nodeport
spec:
  type: NodePort
  externalTrafficPolicy: Local
  selector:
    app: web
  ports:
    - port: 80
      targetPort: 8080
```

## Advanced Troubleshooting Guide

1. Check Node Network Connectivity:
```bash
# Test node port accessibility
for node in $(kubectl get nodes -o jsonpath='{.items[*].status.addresses[?(@.type=="InternalIP")].address}'); do
  curl -v $node:30080
done
```

2. Verify Service Endpoints:
```bash
# Get endpoints
kubectl get endpoints my-nodeport
kubectl describe endpoints my-nodeport
```

3. Check iptables Rules:
```bash
# On node
sudo iptables-save | grep <nodeport>
```

4. Monitor Service Traffic:
```bash
# Install tcpdump on node
sudo tcpdump -n port <nodeport>
```

5. Check kube-proxy Logs:
```bash
# Get kube-proxy logs
kubectl logs -n kube-system -l k8s-app=kube-proxy
```

## Additional NodePort Commands

```bash
# Get node IPs and NodePort
NODE_IP=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[0].address}')
NODE_PORT=$(kubectl get svc my-nodeport -o=jsonpath='{.spec.ports[0].nodePort}')
curl $NODE_IP:$NODE_PORT

# Check if service is accessible
nc -zv <node-ip> <node-port>

# Monitor service events
kubectl get events --field-selector involvedObject.kind=Service

# View service configuration
kubectl get svc my-nodeport -o yaml
```