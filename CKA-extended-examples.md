## CKA Extended Examples — recent-style tasks and snippets

This file collects extra YAML snippets and kubectl/kubeadm commands commonly seen in recent CKA tasks. Keep a copy on your allowed GitHub tab for quick copy/paste.

Table of contents
- RBAC (Role, RoleBinding, ServiceAccount)
- ConfigMap and Secret examples
- Ingress with TLS (minimal)
- NetworkPolicy allow/deny patterns
- StatefulSet with PVC template
- Horizontal Pod Autoscaler (HPA)
- CronJob (batch/v1)
- initContainers and lifecycle hooks
- ResourceQuota and LimitRange
- Useful kubectl advanced commands and patterns

---

### RBAC

ServiceAccount + Role + RoleBinding (namespace-scoped)
```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: demo-sa
  namespace: default

---
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: pod-reader
  namespace: default
rules:
- apiGroups: [""]
  resources: ["pods"]
  verbs: ["get", "watch", "list"]

---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: read-pods-binding
  namespace: default
subjects:
- kind: ServiceAccount
  name: demo-sa
  namespace: default
roleRef:
  kind: Role
  name: pod-reader
  apiGroup: rbac.authorization.k8s.io
```

Quick commands
- Create serviceaccount: `kubectl create sa demo-sa -n default`
- Check effective permissions: `kubectl auth can-i list pods --as=system:serviceaccount:default:demo-sa -n default`

---

### ConfigMap and Secret

ConfigMap from literal / file
```bash
kubectl create configmap demo-cm --from-literal=LOG_LEVEL=debug
kubectl create configmap demo-cm-file --from-file=app.conf
kubectl create configmap demo-cm -o yaml --dry-run=client > cm.yaml
```

Secret from literal / file (base64 handled by kubectl)
```bash
kubectl create secret generic demo-secret --from-literal=DB_PASS='S3cr3t' -n default
kubectl create secret generic tls-secret --from-file=tls.crt=./tls.crt --from-file=tls.key=./tls.key
```

Mounting ConfigMap & Secret (pod snippet)
```yaml
envFrom:
  - configMapRef:
      name: demo-cm
  - secretRef:
      name: demo-secret

volumes:
  - name: config
    configMap:
      name: demo-cm
  - name: tls
    secret:
      secretName: tls-secret
```

---

### Ingress with TLS (minimal, requires ingress controller present)
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: example-tls
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
spec:
  tls:
  - hosts:
    - example.local
    secretName: example-tls-secret
  rules:
  - host: example.local
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: nginx-svc
            port:
              number: 80
```

Create TLS secret (if you have cert/key files):
```bash
kubectl create secret tls example-tls-secret --cert=./tls.crt --key=./tls.key -n default
```

---

### NetworkPolicy

Default deny ingress to pods in namespace `default`, then allow traffic from pods with label `app=frontend` to pods labeled `app=backend` on port 8080.

Default deny all ingress/egress (deny by default)
```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny
  namespace: default
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  - Egress
```

Allow frontend -> backend on TCP/8080
```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-frontend-to-backend
  namespace: default
spec:
  podSelector:
    matchLabels:
      app: backend
  ingress:
  - from:
    - podSelector:
        matchLabels:
          app: frontend
    ports:
    - protocol: TCP
      port: 8080
```

Quick tests
- Create a dnsutils/debug pod and `nc -zv backend 8080` or `curl http://backend:8080` to validate connectivity.

---

### StatefulSet with PVC template
```yaml
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: web
spec:
  serviceName: "web-svc"
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
        image: nginx:1.21
        ports:
        - containerPort: 80
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

Notes: each replica gets its own PVC (web-0, web-1, web-2) using the volumeClaimTemplates.

---

### Horizontal Pod Autoscaler (HPA)
```bash
# create HPA based on CPU utilization (metrics-server must be installed)
kubectl autoscale deployment nginx --cpu-percent=50 --min=1 --max=5
kubectl get hpa
```

HPA YAML (v2 uses metrics API; simple v1 example)
```yaml
apiVersion: autoscaling/v1
kind: HorizontalPodAutoscaler
metadata:
  name: nginx-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: nginx
  minReplicas: 1
  maxReplicas: 5
  targetCPUUtilizationPercentage: 50
```

---

### CronJob (batch/v1)
```yaml
apiVersion: batch/v1
kind: CronJob
metadata:
  name: hello-cron
spec:
  schedule: "*/1 * * * *"
  jobTemplate:
    spec:
      template:
        spec:
          containers:
          - name: hello
            image: busybox
            args:
            - /bin/sh
            - -c
            - date; echo Hello from the CronJob
          restartPolicy: OnFailure
```

---

### initContainers and lifecycle
```yaml
spec:
  initContainers:
  - name: init-myservice
    image: busybox
    command: ['sh', '-c', 'echo init; sleep 2']
  containers:
  - name: myapp
    image: nginx
    lifecycle:
      postStart:
        exec:
          command: ["/bin/sh","-c","echo started > /tmp/start.txt"]
```

---

### ResourceQuota and LimitRange
ResourceQuota (namespace) example
```yaml
apiVersion: v1
kind: ResourceQuota
metadata:
  name: compute-resources
  namespace: default
spec:
  hard:
    requests.cpu: "2"
    requests.memory: 4Gi
    limits.cpu: "4"
    limits.memory: 8Gi
    pods: "10"
```

LimitRange example (enforce default/maximum container resources)
```yaml
apiVersion: v1
kind: LimitRange
metadata:
  name: limits
spec:
  limits:
  - default:
      cpu: 500m
      memory: 256Mi
    defaultRequest:
      cpu: 100m
      memory: 64Mi
    type: Container
```

---

### Useful kubectl advanced commands & exam patterns

- Wait for rollout or condition:
  ```bash
  kubectl rollout status deployment/mydep --timeout=60s
  kubectl wait --for=condition=Ready pod -l app=myapp --timeout=90s
  ```
- Patch examples (strategic merge):
  ```bash
  kubectl patch deployment mydep -p '{"spec":{"replicas":3}}'
  # JSON patch
  kubectl patch deployment mydep --type='json' -p='[{"op":"replace","path":"/spec/replicas","value":2}]'
  ```
- Apply directory, prune unused resources:
  ```bash
  kubectl apply -f ./manifests --prune -l app=myapp
  ```
- Create and edit ephemeral debug container (if kubectl supports):
  ```bash
  kubectl debug -it pod/myapp --image=busybox --target=containername
  ```
- Auth checks:
  ```bash
  kubectl auth can-i create deployment -n default
  kubectl auth can-i --as=system:serviceaccount:default:demo-sa get pods -n default
  ```
- Get API documentation quickly (exam): `kubectl explain <resource> --recursive`
- Top/metrics (if metrics-server installed): `kubectl top nodes` / `kubectl top pods -n <ns>`
- Copy files to/from pod (directory): `kubectl cp ./localdir <pod>:/tmp -c containername -n ns`
- Exec into pod and check env or files:
  ```bash
  kubectl exec -it pod/myapp -n default -- env
  kubectl exec -it pod/myapp -n default -- cat /etc/hosts
  ```

---

Keep this file updated with any snippets you find during practice. Add them to your GitHub allowed tab for fast reuse during the exam.
