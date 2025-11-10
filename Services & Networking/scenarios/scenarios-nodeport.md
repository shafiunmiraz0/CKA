# NodePort Service Scenarios

## Scenario 1: Basic NodePort Service
Task: Create a NodePort service for external access

```yaml
apiVersion: v1
kind: Service
metadata:
  name: my-nodeport
spec:
  type: NodePort
  selector:
    app: web
  ports:
    - port: 80          # Service port
      targetPort: 8080  # Container port
      nodePort: 30080   # Port on node (30000-32767)
```

```bash
# Create service
kubectl apply -f nodeport.yaml

# Verify service
kubectl get svc my-nodeport
kubectl describe svc my-nodeport

# Access service
curl <node-ip>:30080
```

## Scenario 2: NodePort with Multiple Ports
Task: Configure NodePort service with multiple ports

```yaml
apiVersion: v1
kind: Service
metadata:
  name: multi-nodeport
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

## Scenario 3: Dynamic NodePort Assignment
Task: Let Kubernetes assign random NodePort

```yaml
apiVersion: v1
kind: Service
metadata:
  name: dynamic-nodeport
spec:
  type: NodePort
  selector:
    app: web
  ports:
    - port: 80
      targetPort: 8080
      # nodePort field omitted - will be assigned automatically
```

```bash
# Get assigned NodePort
kubectl get svc dynamic-nodeport -o=jsonpath='{.spec.ports[0].nodePort}'
```

## Scenario 4: NodePort Troubleshooting
Task: Debug common NodePort issues

```bash
# 1. Check service status
kubectl get svc my-nodeport
kubectl describe svc my-nodeport

# 2. Verify pod selector matches
kubectl get pods --selector=app=web --show-labels

# 3. Check node status
kubectl get nodes -o wide

# 4. Test service internally
kubectl run test-pod --image=busybox -it --rm -- wget -qO- my-nodeport

# 5. Check node port access
curl <node-ip>:<node-port>

# 6. Verify kube-proxy status
kubectl get pods -n kube-system | grep kube-proxy
kubectl logs -n kube-system kube-proxy-xxxxx
```

## Quick Commands for NodePort

```bash
# Create NodePort service
kubectl expose deployment nginx --type=NodePort --port=80

# Get service details
kubectl get svc

# Get specific NodePort
kubectl get svc my-nodeport -o=jsonpath='{.spec.ports[0].nodePort}'

# Delete service
kubectl delete svc my-nodeport

# Edit service
kubectl edit svc my-nodeport
```