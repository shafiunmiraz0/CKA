# Service Account, ClusterRole & ClusterRoleBinding

## Purpose
Create ServiceAccounts and grant cluster-level permissions using ClusterRole and ClusterRoleBinding. Useful for exam tasks requiring cluster-scoped access for service accounts.

## Create a ServiceAccount
```bash
kubectl create serviceaccount app-sa -n default
kubectl get sa -n default
```

## Create ClusterRole (cluster-scoped permissions)
```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: pod-reader
rules:
- apiGroups: [""]
  resources: ["pods"]
  verbs: ["get","watch","list"]
```

## Bind ServiceAccount to ClusterRole
```yaml
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

## Create Role and RoleBinding (namespace-scoped)
```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: config-reader
  namespace: dev
rules:
- apiGroups: [""]
  resources: ["configmaps"]
  verbs: ["get","list"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: bind-config-reader
  namespace: dev
subjects:
- kind: ServiceAccount
  name: app-sa
  namespace: default
roleRef:
  kind: Role
  name: config-reader
  apiGroup: rbac.authorization.k8s.io
```

## Troubleshooting
- `Forbidden` errors: check `kubectl auth can-i` and verify Role/ClusterRole and the binding.
```bash
kubectl auth can-i get pods --as=system:serviceaccount:default:app-sa
kubectl describe clusterrolebinding read-pods-global
```
- Ensure namespace is correct for ServiceAccount in RoleBinding/ClusterRoleBinding.

## Exam tips
- Use ClusterRoleBinding only when cluster-wide access is required.
- Prefer Role + RoleBinding for least privilege in namespaces.
- Use `kubectl create clusterrolebinding --clusterrole=pod-reader --serviceaccount=default:app-sa read-pods-global` for speed.
