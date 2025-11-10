# Service Integration Scenarios

## 1. Service Types

### ClusterIP Service
```yaml
apiVersion: v1
kind: Service
metadata:
  name: backend-service
spec:
  type: ClusterIP
  selector:
    app: backend
  ports:
  - port: 80
    targetPort: 8080
```

### NodePort Service
```yaml
apiVersion: v1
kind: Service
metadata:
  name: frontend-service
spec:
  type: NodePort
  selector:
    app: frontend
  ports:
  - port: 80
    targetPort: 80
    nodePort: 30080
```

### LoadBalancer Service
```yaml
apiVersion: v1
kind: Service
metadata:
  name: lb-service
spec:
  type: LoadBalancer
  selector:
    app: web
  ports:
  - port: 80
    targetPort: 8080
```

## 2. Service Discovery

### Pod with Service Discovery
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: client-pod
spec:
  containers:
  - name: client
    image: nginx
    env:
    - name: BACKEND_SERVICE
      value: "backend-service.default.svc.cluster.local"
    - name: BACKEND_PORT
      value: "80"
```

### DNS Configuration
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: dns-test
spec:
  containers:
  - name: dns-test
    image: busybox
    command:
      - sleep
      - "3600"
  dnsPolicy: ClusterFirst
```

## 3. Headless Services

### Headless Service Definition
```yaml
apiVersion: v1
kind: Service
metadata:
  name: headless-service
spec:
  clusterIP: None
  selector:
    app: stateful-app
  ports:
  - port: 80
    targetPort: 80
```

### StatefulSet with Headless Service
```yaml
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: web
spec:
  serviceName: headless-service
  replicas: 3
  selector:
    matchLabels:
      app: stateful-app
  template:
    metadata:
      labels:
        app: stateful-app
    spec:
      containers:
      - name: nginx
        image: nginx
```

## 4. Service Integration with External Services

### External Name Service
```yaml
apiVersion: v1
kind: Service
metadata:
  name: external-service
spec:
  type: ExternalName
  externalName: api.external-service.com
```

### External IPs Service
```yaml
apiVersion: v1
kind: Service
metadata:
  name: external-ip-service
spec:
  selector:
    app: frontend
  ports:
  - port: 80
    targetPort: 80
  externalIPs:
  - 80.11.12.10
```

## Commands Reference

### Service Management
```bash
# Create service
kubectl expose deployment nginx --port=80 --type=ClusterIP

# Get service information
kubectl get services
kubectl describe service <service-name>

# Test service connectivity
kubectl run test-pod --image=busybox -it --rm -- wget -qO- http://service-name

# Get endpoints
kubectl get endpoints <service-name>
```

### DNS Troubleshooting
```bash
# Create DNS debugging pod
kubectl run dns-test --image=busybox:1.28 --rm -it -- nslookup kubernetes.default

# Check DNS configuration
kubectl get configmap coredns -n kube-system -o yaml

# Test service resolution
kubectl exec -it <pod-name> -- nslookup <service-name>
```

## Best Practices

### 1. Service Design
- Choose appropriate service type
- Use meaningful service names
- Implement proper labels and selectors
- Consider security implications

### 2. Service Discovery
- Use DNS names over IP addresses
- Implement proper health checks
- Consider using headless services for stateful apps
- Use proper namespace naming

### 3. Load Balancing
- Configure appropriate session affinity
- Set proper timeouts
- Monitor service endpoints
- Implement proper health checks

## Troubleshooting Guide

### Common Issues

1. **Service Not Accessible**
```bash
# Check service
kubectl describe service <service-name>

# Verify endpoints
kubectl get endpoints <service-name>

# Check pod labels
kubectl get pods --show-labels
```

2. **DNS Resolution Issues**
```bash
# Check CoreDNS
kubectl get pods -n kube-system -l k8s-app=kube-dns
kubectl logs -n kube-system -l k8s-app=kube-dns

# Test DNS resolution
kubectl run dns-test --image=busybox:1.28 --rm -it -- nslookup <service-name>
```

3. **Load Balancing Problems**
```bash
# Check service distribution
kubectl get endpoints <service-name>

# Verify node ports
kubectl get service <service-name> -o wide
```

### Service Patterns

1. **Multi-Port Service**
```yaml
apiVersion: v1
kind: Service
metadata:
  name: multi-port-service
spec:
  selector:
    app: my-app
  ports:
  - name: http
    port: 80
    targetPort: 8080
  - name: https
    port: 443
    targetPort: 8443
```

2. **Internal Load Balancing**
```yaml
apiVersion: v1
kind: Service
metadata:
  name: internal-lb
  annotations:
    cloud.google.com/load-balancer-type: "Internal"
spec:
  type: LoadBalancer
  selector:
    app: internal-app
  ports:
  - port: 80
    targetPort: 8080
```

3. **Service with Session Affinity**
```yaml
apiVersion: v1
kind: Service
metadata:
  name: sticky-service
spec:
  selector:
    app: web
  sessionAffinity: ClientIP
  sessionAffinityConfig:
    clientIP:
      timeoutSeconds: 10800
  ports:
  - port: 80
    targetPort: 80
```