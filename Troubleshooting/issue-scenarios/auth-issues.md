# Authentication and Authorization Troubleshooting Scenarios

## Common Authentication Issues

### 1. Service Account Issues
**Symptoms:**
- Pod can't access API server
- Authentication failures
- Token mounting issues

**Debugging Steps:**
```bash
# Check service account
kubectl get serviceaccount
kubectl describe serviceaccount <sa-name>

# Verify token secret
kubectl get secret
kubectl describe secret <secret-name>

# Check pod service account mounting
kubectl describe pod <pod-name> | grep "Service Account"
```

**Example ServiceAccount:**
```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: app-sa
---
apiVersion: v1
kind: Secret
metadata:
  name: app-sa-token
  annotations:
    kubernetes.io/service-account.name: app-sa
type: kubernetes.io/service-account-token
```

### 2. RBAC Configuration Issues
**Symptoms:**
- Permission denied errors
- Unauthorized access
- Missing role bindings

**Debugging Steps:**
```bash
# Check roles and bindings
kubectl get roles,rolebindings
kubectl get clusterroles,clusterrolebindings

# Verify permissions
kubectl auth can-i <verb> <resource> --as <user> -n <namespace>

# Check RBAC rules
kubectl describe role <role-name>
kubectl describe rolebinding <rolebinding-name>
```

**Example RBAC Configuration:**
```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: pod-reader
rules:
- apiGroups: [""]
  resources: ["pods"]
  verbs: ["get", "list", "watch"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: read-pods
subjects:
- kind: ServiceAccount
  name: app-sa
roleRef:
  kind: Role
  name: pod-reader
  apiGroup: rbac.authorization.k8s.io
```

### 3. Certificate Issues
**Symptoms:**
- x509 certificate errors
- API server connection failures
- Client authentication errors

**Debugging Steps:**
```bash
# Check certificate expiration
kubeadm certs check-expiration

# Verify certificate content
openssl x509 -in /etc/kubernetes/pki/apiserver.crt -text -noout

# Renew certificates
kubeadm certs renew all
```

### 4. API Access Issues
**Symptoms:**
- kubectl commands failing
- API server connectivity issues
- Authentication timeout

**Debugging Steps:**
```bash
# Check kubeconfig
kubectl config view
kubectl config get-contexts

# Test API server access
curl -k https://<api-server-ip>:6443/healthz

# Verify credentials
kubectl config current-context
```

## Quick Reference Commands

```bash
# ServiceAccount Commands
kubectl get sa
kubectl create sa <name>
kubectl delete sa <name>

# RBAC Commands
kubectl get roles,rolebindings --all-namespaces
kubectl auth can-i --list
kubectl auth reconcile -f rbac.yaml

# Certificate Commands
openssl x509 -in cert.crt -text -noout
kubeadm certs check-expiration
kubeadm certs renew all

# Authentication Debug
kubectl config view
kubectl config get-contexts
kubectl config use-context <context-name>
```

## Common Configurations

### 1. Pod with ServiceAccount
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: app-pod
spec:
  serviceAccountName: app-sa
  containers:
  - name: app
    image: nginx
    volumeMounts:
    - name: sa-token
      mountPath: /var/run/secrets/kubernetes.io/serviceaccount
  volumes:
  - name: sa-token
    projected:
      sources:
      - serviceAccountToken:
          path: token
          expirationSeconds: 3600
```

### 2. ClusterRole and ClusterRoleBinding
```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: pod-reader
rules:
- apiGroups: [""]
  resources: ["pods"]
  verbs: ["get", "list", "watch"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: read-pods-global
subjects:
- kind: ServiceAccount
  name: app-sa
  namespace: default
roleRef:
  kind: ClusterRole
  name: pod-reader
  apiGroup: rbac.authorization.k8s.io
```

### 3. User Authentication Configuration
```yaml
apiVersion: v1
kind: Config
clusters:
- cluster:
    certificate-authority-data: <ca-data>
    server: https://kubernetes.default.svc
  name: kubernetes
users:
- name: developer
  user:
    client-certificate-data: <cert-data>
    client-key-data: <key-data>
contexts:
- context:
    cluster: kubernetes
    user: developer
  name: dev-context
current-context: dev-context
```