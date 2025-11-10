# ClusterIP Service Scenarios

## Scenario 1: Basic ClusterIP Service
Task: Create a ClusterIP service for a web application

```yaml
apiVersion: v1
kind: Service
metadata:
  name: web-service
spec:
  type: ClusterIP
  selector:
    app: web
  ports:
    - port: 80
      targetPort: 8080
```

```bash
# Create the service
kubectl apply -f web-service.yaml

# Verify service
kubectl get svc web-service
kubectl describe svc web-service

# Test service
kubectl run test-pod --image=busybox -it --rm -- wget -qO- web-service
```

## Scenario 2: Service with Session Affinity
Task: Create a ClusterIP service with session affinity

```yaml
apiVersion: v1
kind: Service
metadata:
  name: web-sticky
spec:
  type: ClusterIP
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

## Scenario 3: Headless Service
Task: Create a headless service for stateful applications

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
      targetPort: 8080
```

## Scenario 4: Troubleshooting ClusterIP
Task: Debug common ClusterIP issues

```bash
# 1. Verify service
kubectl get svc my-clusterip

# 2. Check endpoints
kubectl get endpoints my-clusterip

# 3. Verify pod labels
kubectl get pods --selector=app=my-app --show-labels

# 4. Test DNS resolution
kubectl run dns-test --image=busybox -it --rm -- nslookup my-clusterip.default.svc.cluster.local

# 5. Check kube-proxy status
kubectl get pods -n kube-system | grep kube-proxy
```