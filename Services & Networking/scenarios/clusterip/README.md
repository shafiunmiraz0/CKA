# ClusterIP Service Scenario

## Scenario Description
Create and manage ClusterIP services for internal cluster communication.

## Requirements
1. Create a deployment with multiple pods
2. Expose the deployment using ClusterIP service
3. Test internal communication
4. Troubleshoot common issues

## Solution

### 1. Create Deployment
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-deployment
spec:
  replicas: 3
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
        image: nginx:1.14.2
        ports:
        - containerPort: 80
```

```bash
kubectl apply -f deployment.yaml
```

### 2. Create ClusterIP Service
```yaml
apiVersion: v1
kind: Service
metadata:
  name: nginx-service
spec:
  type: ClusterIP
  selector:
    app: nginx
  ports:
    - protocol: TCP
      port: 80        # Service port
      targetPort: 80  # Container port
```

```bash
kubectl apply -f service.yaml
```

### 3. Verification Steps
```bash
# Check service details
kubectl get service nginx-service
kubectl describe service nginx-service

# Check endpoints
kubectl get endpoints nginx-service

# Test service from another pod
kubectl run test-pod --image=busybox -it --rm -- wget -O- http://nginx-service.default.svc.cluster.local
```

## Common Issues and Solutions

### 1. Service Not Working
```bash
# Check if pods are running
kubectl get pods -l app=nginx

# Verify pod labels match service selector
kubectl describe service nginx-service | grep Selector
kubectl get pods --show-labels

# Check endpoints
kubectl get endpoints nginx-service
```

### 2. DNS Resolution Issues
```bash
# Check CoreDNS pods
kubectl get pods -n kube-system -l k8s-app=kube-dns

# Test DNS resolution
kubectl run dnsutils --image=tutum/dnsutils --command -- sleep infinity
kubectl exec -it dnsutils -- nslookup nginx-service
```

### 3. Network Connectivity
```bash
# Check network policies
kubectl get networkpolicies

# Test connectivity using temporary pod
kubectl run tmp-shell --rm -i --tty --image nicolaka/netshoot -- /bin/bash
```

## Best Practices
1. Always use meaningful service names
2. Document service ports and mappings
3. Use appropriate labels and selectors
4. Implement health checks
5. Consider network policies

## Additional Commands
```bash
# Quick service creation
kubectl expose deployment nginx-deployment --port=80 --type=ClusterIP

# Port forwarding for testing
kubectl port-forward service/nginx-service 8080:80

# Check service logs
kubectl logs -l app=nginx

# Scale deployment
kubectl scale deployment nginx-deployment --replicas=5
```

## YAML Templates

### Service with Multiple Ports
```yaml
apiVersion: v1
kind: Service
metadata:
  name: multi-port-service
spec:
  type: ClusterIP
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

### Service with Session Affinity
```yaml
apiVersion: v1
kind: Service
metadata:
  name: session-affinity-service
spec:
  type: ClusterIP
  sessionAffinity: ClientIP
  selector:
    app: my-app
  ports:
  - port: 80
    targetPort: 80
```