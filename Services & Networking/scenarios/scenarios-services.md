# Service Scenarios

## Scenario 1: Create and Expose a Service
Task: Create a deployment and expose it as a service

```bash
# Create deployment
kubectl create deployment web --image=nginx

# Expose deployment as service
kubectl expose deployment web --port=80 --type=ClusterIP

# Verify
kubectl get svc web
kubectl describe svc web
```

## Scenario 2: Service with Multiple Ports
Task: Create a service exposing multiple ports

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

```bash
# Apply the configuration
kubectl apply -f multi-port-service.yaml

# Verify ports
kubectl describe svc multi-port-service
```

## Scenario 3: Service Without Selectors
Task: Create a service that manually defines its endpoints

```yaml
# Service definition
apiVersion: v1
kind: Service
metadata:
  name: external-service
spec:
  ports:
  - port: 80

---
# Endpoints definition
apiVersion: v1
kind: Endpoints
metadata:
  name: external-service
subsets:
- addresses:
  - ip: 192.168.1.100
  ports:
  - port: 80
```

## Scenario 4: Troubleshooting Service Connectivity
Task: Debug service connectivity issues

```bash
# 1. Check service exists
kubectl get svc my-service

# 2. Verify endpoints
kubectl get endpoints my-service

# 3. Check pod labels match service selector
kubectl get pods --show-labels

# 4. Test connectivity from another pod
kubectl run test-pod --image=busybox -it --rm -- wget -qO- my-service

# 5. Check service DNS resolution
kubectl run test-dns --image=busybox -it --rm -- nslookup my-service
```