# NodePort Service Configuration

## Scenario Description
Configure NodePort services for external access to applications in the cluster.

## Requirements
1. Create a deployment
2. Expose deployment via NodePort
3. Access application externally
4. Troubleshoot common issues

## Solution

### 1. Create Deployment
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web-app
spec:
  replicas: 3
  selector:
    matchLabels:
      app: web
  template:
    metadata:
      labels:
        app: web
    spec:
      containers:
      - name: nginx
        image: nginx:1.14.2
        ports:
        - containerPort: 80
```

### 2. Create NodePort Service
```yaml
apiVersion: v1
kind: Service
metadata:
  name: web-service
spec:
  type: NodePort
  selector:
    app: web
  ports:
    - port: 80          # Service port
      targetPort: 80    # Container port
      nodePort: 30080   # External port (30000-32767)
```

## Commands Reference

### Service Management
```bash
# Create service
kubectl expose deployment web-app --type=NodePort --port=80

# Get service details
kubectl get service web-service
kubectl describe service web-service

# Get node IPs
kubectl get nodes -o wide

# Delete service
kubectl delete service web-service
```

### Testing Access
```bash
# Get NodePort
kubectl get svc web-service -o=jsonpath='{.spec.ports[0].nodePort}'

# Test locally
curl http://<node-ip>:30080

# Test from pod
kubectl run test-pod --image=busybox -it --rm -- wget -O- http://web-service:80
```

## Troubleshooting Steps

### 1. Service Issues
```bash
# Check service status
kubectl describe service web-service

# Verify endpoints
kubectl get endpoints web-service

# Check pod labels
kubectl get pods --show-labels
```

### 2. Network Issues
```bash
# Check node ports
sudo netstat -tulpn | grep 30080

# Verify firewall rules
sudo iptables -L

# Check kube-proxy logs
kubectl logs -n kube-system -l k8s-app=kube-proxy
```

### 3. Pod Health
```bash
# Check pod status
kubectl get pods -l app=web

# Check pod logs
kubectl logs -l app=web

# Describe pods
kubectl describe pods -l app=web
```

## Best Practices

1. Port Selection:
   - Use random port allocation when possible
   - Document port assignments
   - Consider port conflicts

2. Security:
   - Implement firewall rules
   - Use network policies
   - Consider authentication

3. High Availability:
   - Deploy multiple replicas
   - Use anti-affinity rules
   - Monitor node health

## YAML Templates

### NodePort with Multiple Ports
```yaml
apiVersion: v1
kind: Service
metadata:
  name: multi-port-service
spec:
  type: NodePort
  selector:
    app: web
  ports:
  - name: http
    port: 80
    targetPort: 8080
    nodePort: 30080
  - name: https
    port: 443
    targetPort: 8443
    nodePort: 30443
```

### Service with Session Affinity
```yaml
apiVersion: v1
kind: Service
metadata:
  name: sticky-service
spec:
  type: NodePort
  sessionAffinity: ClientIP
  selector:
    app: web
  ports:
  - port: 80
    targetPort: 80
    nodePort: 30080
```

## Common Issues and Solutions

1. Port Already in Use
```bash
# Check port usage
netstat -tulpn | grep 30080

# Use different nodePort
kubectl patch svc web-service -p '{"spec":{"ports":[{"port":80,"nodePort":30081}]}}'
```

2. Connection Refused
```bash
# Check if pods are running
kubectl get pods -l app=web

# Check if service is correctly configured
kubectl describe svc web-service

# Verify kube-proxy is running
kubectl get pods -n kube-system | grep kube-proxy
```

3. Load Balancing Issues
```bash
# Check endpoint distribution
kubectl describe endpoints web-service

# View service configuration
kubectl get svc web-service -o yaml
```

## Testing and Verification

1. Basic Connectivity
```bash
# Test from outside cluster
curl http://<node-ip>:30080

# Test from inside cluster
kubectl run test-pod --image=busybox -it --rm -- wget -O- http://web-service
```

2. Load Balancing
```bash
# Multiple requests to check distribution
for i in {1..10}; do curl http://<node-ip>:30080; done
```

3. Session Affinity
```bash
# Test sticky sessions
curl -c cookies.txt http://<node-ip>:30080
curl -b cookies.txt http://<node-ip>:30080
```