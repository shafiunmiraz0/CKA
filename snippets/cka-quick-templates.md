# CKA quick commands & template manifests

This file collects extra commands and copy/paste-ready YAML templates useful during the CKA exam. Keep it open for quick edits.

Quick kubectl command snippets
- Get resources quickly across namespaces: `kubectl get all -A`
- Describe a failing object: `kubectl describe pod <pod> -n <ns>`
- Tail logs from a container: `kubectl logs -f <pod> -c <container> -n <ns>`
- Previous container logs: `kubectl logs <pod> -n <ns> --previous`
- Apply a patch (JSON patch): `kubectl patch deploy myapp -n myns --type='json' -p '[{"op":"replace","path":"/spec/template/spec/containers/0/image","value":"myimage:tag"}]'`
- Edit resource quickly: `kubectl edit deploy/<name> -n <ns>`
- One-line rollout restart: `kubectl rollout restart deployment/<name> -n <ns>`
- Force-delete stuck pod: `kubectl delete pod <pod> -n <ns> --grace-period=0 --force`

Admin & debugging
- Cordon/Drain node: `kubectl cordon <node>` / `kubectl drain <node> --ignore-daemonsets --delete-local-data`
- Check events (sorted): `kubectl get events -A --sort-by=.metadata.creationTimestamp`
- Check resource usage (if metrics-server installed): `kubectl top nodes` / `kubectl top pods -n <ns>`
- Approve pending CSR (node bootstrap): `kubectl certificate approve <csr-name>`

Networking quick tests
- Port-forward a pod or service: `kubectl port-forward svc/my-svc 8080:80 -n <ns>`
- Exec into a debug pod: `kubectl run -i --tty debug --image=radial/busyboxplus:curl --restart=Never -- sh`

Storage quick tests
- List PVCs: `kubectl get pvc -A`
- Describe PVC: `kubectl describe pvc <pvc> -n <ns>`
- Expand a PVC (if storage class allows): `kubectl patch pvc <pvc> -n <ns> -p '{"spec":{"resources":{"requests":{"storage":"2Gi"}}}}'`

Templates

1) Deployment with readiness/liveness probes and resources

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: webapp
  namespace: myns
spec:
  replicas: 2
  selector:
    matchLabels:
      app: webapp
  template:
    metadata:
      labels:
        app: webapp
    spec:
      containers:
      - name: web
        image: nginx:1.23
        ports:
        - containerPort: 80
        readinessProbe:
          httpGet:
            path: /
            port: 80
          initialDelaySeconds: 5
          periodSeconds: 5
        livenessProbe:
          httpGet:
            path: /healthz
            port: 80
          initialDelaySeconds: 15
          periodSeconds: 20
        resources:
          requests:
            cpu: "100m"
            memory: "128Mi"
          limits:
            cpu: "500m"
            memory: "256Mi"
```

2) StatefulSet with volumeClaimTemplates (basic)

```yaml
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: web-ss
  namespace: myns
spec:
  serviceName: "web-ss"
  replicas: 2
  selector:
    matchLabels:
      app: web-ss
  template:
    metadata:
      labels:
        app: web-ss
    spec:
      containers:
      - name: web
        image: nginx:1.23
        ports:
        - containerPort: 80
  volumeClaimTemplates:
  - metadata:
      name: data
    spec:
      accessModes: [ "ReadWriteOnce" ]
      resources:
        requests:
          storage: 1Gi
```

3) StorageClass (CSI example - replace provisioner with your provider)

```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: csi-fast
provisioner: csi.example.com
parameters:
  type: gp2
reclaimPolicy: Delete
volumeBindingMode: Immediate
```

4) VolumeSnapshotClass and VolumeSnapshot (CSI snapshot example)

```yaml
apiVersion: snapshot.storage.k8s.io/v1
kind: VolumeSnapshotClass
metadata:
  name: csi-snap-class
driver: csi.example.com
deletionPolicy: Delete

---
apiVersion: snapshot.storage.k8s.io/v1
kind: VolumeSnapshot
metadata:
  name: my-snapshot
  namespace: myns
spec:
  volumeSnapshotClassName: csi-snap-class
  source:
    persistentVolumeClaimName: mypvc
```

5) PVC expansion example (request larger size)

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: expand-pvc
  namespace: myns
spec:
  accessModes:
  - ReadWriteOnce
  resources:
    requests:
      storage: 2Gi
  storageClassName: csi-fast
```

6) LimitRange + ResourceQuota example

```yaml
apiVersion: v1
kind: ResourceQuota
metadata:
  name: rq-demo
  namespace: myns
spec:
  hard:
    pods: "10"
    requests.cpu: "4"
    requests.memory: 8Gi

---
apiVersion: v1
kind: LimitRange
metadata:
  name: lr-demo
  namespace: myns
spec:
  limits:
  - default:
      cpu: "200m"
      memory: "256Mi"
    defaultRequest:
      cpu: "100m"
      memory: "128Mi"
    type: Container
```

7) ServiceAccount + Role + RoleBinding template

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: ci-sa
  namespace: myns

---
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: pod-reader
  namespace: myns
rules:
- apiGroups: [""]
  resources: ["pods"]
  verbs: ["get","watch","list"]

---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: pod-reader-binding
  namespace: myns
subjects:
- kind: ServiceAccount
  name: ci-sa
  namespace: myns
roleRef:
  kind: Role
  name: pod-reader
  apiGroup: rbac.authorization.k8s.io
```

Usage notes
- Copy the snippet into a file and `kubectl apply -f` it. Edit `namespace`, `names`, and provider-specific fields (provisioner) before applying.
