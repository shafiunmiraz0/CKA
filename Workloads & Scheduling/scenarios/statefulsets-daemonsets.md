# StatefulSets and DaemonSets Management

## 1. StatefulSet Configurations

### Basic StatefulSet
```yaml
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: web
spec:
  serviceName: "nginx"
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
        image: nginx
        ports:
        - containerPort: 80
          name: web
        volumeMounts:
        - name: www
          mountPath: /usr/share/nginx/html
  volumeClaimTemplates:
  - metadata:
      name: www
    spec:
      accessModes: [ "ReadWriteOnce" ]
      resources:
        requests:
          storage: 1Gi
```

### StatefulSet with Headless Service
```yaml
apiVersion: v1
kind: Service
metadata:
  name: nginx
  labels:
    app: nginx
spec:
  ports:
  - port: 80
    name: web
  clusterIP: None
  selector:
    app: nginx
---
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: web
spec:
  serviceName: "nginx"
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
        image: nginx
        ports:
        - containerPort: 80
          name: web
```

## 2. DaemonSet Configurations

### Basic DaemonSet
```yaml
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: monitoring-agent
spec:
  selector:
    matchLabels:
      name: monitoring-agent
  template:
    metadata:
      labels:
        name: monitoring-agent
    spec:
      containers:
      - name: agent
        image: monitoring-agent:v1
```

### DaemonSet with Node Selection
```yaml
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: gpu-agent
spec:
  selector:
    matchLabels:
      name: gpu-agent
  template:
    metadata:
      labels:
        name: gpu-agent
    spec:
      nodeSelector:
        gpu: "true"
      containers:
      - name: gpu-agent
        image: gpu-agent:v1
```

## 3. Update Strategies

### StatefulSet Update Strategy
```yaml
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: web
spec:
  updateStrategy:
    type: RollingUpdate
    rollingUpdate:
      partition: 2  # Only update pods with ordinal >= 2
```

### DaemonSet Update Strategy
```yaml
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: fluentd
spec:
  updateStrategy:
    type: RollingUpdate
    rollingUpdate:
      maxUnavailable: 1
```

## 4. Advanced Configurations

### StatefulSet with Init Containers
```yaml
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: web
spec:
  serviceName: "nginx"
  replicas: 3
  template:
    spec:
      initContainers:
      - name: init-myservice
        image: busybox:1.28
        command: ['sh', '-c', 'until nslookup myservice; do echo waiting for myservice; sleep 2; done;']
      containers:
      - name: nginx
        image: nginx
```

### DaemonSet with Resource Limits
```yaml
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: fluentd
spec:
  template:
    spec:
      containers:
      - name: fluentd
        image: fluentd:v1
        resources:
          limits:
            memory: 200Mi
          requests:
            cpu: 100m
            memory: 200Mi
```

## Commands Reference

### StatefulSet Management
```bash
# Create and manage StatefulSets
kubectl create -f statefulset.yaml
kubectl get statefulset
kubectl describe statefulset <name>

# Scale StatefulSet
kubectl scale statefulset <name> --replicas=5

# Update StatefulSet
kubectl rollout status statefulset <name>
kubectl rollout history statefulset <name>
```

### DaemonSet Management
```bash
# Create and manage DaemonSets
kubectl create -f daemonset.yaml
kubectl get daemonset
kubectl describe daemonset <name>

# Update DaemonSet
kubectl rollout status daemonset <name>
kubectl rollout history daemonset <name>

# Delete DaemonSet
kubectl delete daemonset <name>
```

## Troubleshooting Guide

### 1. StatefulSet Issues
```bash
# Check pod ordering
kubectl get pods -l app=<label> -o wide

# Check PVC binding
kubectl get pvc -l app=<label>

# Check headless service
kubectl describe service <service-name>
```

### 2. DaemonSet Issues
```bash
# Verify pod placement
kubectl get pods -o wide | grep <daemonset-name>

# Check node scheduling
kubectl describe node <node-name> | grep Taints

# Check DaemonSet events
kubectl describe daemonset <name>
```

## Best Practices

### StatefulSet Best Practices
1. Use Headless Services for stable network identities
2. Implement proper volume management
3. Consider update strategies carefully
4. Use init containers for dependencies
5. Implement proper backup strategies

### DaemonSet Best Practices
1. Set resource limits and requests
2. Use node selectors and tolerations appropriately
3. Implement proper update strategies
4. Monitor DaemonSet pods
5. Consider security implications

### Example: Production-Ready StatefulSet
```yaml
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: production-db
spec:
  serviceName: "db"
  replicas: 3
  selector:
    matchLabels:
      app: db
  template:
    metadata:
      labels:
        app: db
    spec:
      securityContext:
        fsGroup: 1000
      initContainers:
      - name: init-db
        image: busybox
        command: ['sh', '-c', 'chown -R 1000:1000 /data/db']
        volumeMounts:
        - name: data
          mountPath: /data/db
      containers:
      - name: db
        image: mongo:4.4
        resources:
          requests:
            memory: "1Gi"
            cpu: "500m"
          limits:
            memory: "2Gi"
            cpu: "1000m"
        ports:
        - containerPort: 27017
          name: db
        volumeMounts:
        - name: data
          mountPath: /data/db
        readinessProbe:
          exec:
            command:
            - mongo
            - --eval
            - "db.adminCommand('ping')"
          initialDelaySeconds: 5
          periodSeconds: 10
  volumeClaimTemplates:
  - metadata:
      name: data
    spec:
      accessModes: [ "ReadWriteOnce" ]
      resources:
        requests:
          storage: 10Gi
```

### Example: Production-Ready DaemonSet
```yaml
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: production-logging
spec:
  selector:
    matchLabels:
      name: logging-agent
  updateStrategy:
    type: RollingUpdate
    rollingUpdate:
      maxUnavailable: 1
  template:
    metadata:
      labels:
        name: logging-agent
    spec:
      tolerations:
      - key: node-role.kubernetes.io/master
        effect: NoSchedule
      containers:
      - name: fluentd
        image: fluentd:v1.14
        resources:
          limits:
            memory: 200Mi
            cpu: 500m
          requests:
            cpu: 100m
            memory: 200Mi
        volumeMounts:
        - name: varlog
          mountPath: /var/log
        - name: varlibdockercontainers
          mountPath: /var/lib/docker/containers
          readOnly: true
        securityContext:
          privileged: true
      volumes:
      - name: varlog
        hostPath:
          path: /var/log
      - name: varlibdockercontainers
        hostPath:
          path: /var/lib/docker/containers
```