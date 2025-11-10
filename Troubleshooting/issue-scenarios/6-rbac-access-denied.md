# Scenario: RBAC "forbidden" / access denied

Symptom
- `kubectl get pods` or other commands return `Error from server (Forbidden): ...` or `User "..." cannot ...`.

Quick diagnostics
- kubectl auth can-i <verb> <resource> -n <ns>    # quick check for current user
- kubectl get clusterrolebinding,rolebinding -A | grep <user-or-sa>
- kubectl describe rolebinding <name> -n <ns>

Common causes & fixes

1) Missing Role/RoleBinding or ClusterRole/ClusterRoleBinding

Fix: create an appropriate Role/ClusterRole and bind the user or ServiceAccount.

Example: grant namespace view access to a user (Role + RoleBinding)

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: ns-view
  namespace: myns
rules:
  - apiGroups: [""]
    resources: ["pods","services","endpoints"]
    verbs: ["get","list","watch"]

---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: ns-view-binding
  namespace: myns
subjects:
  - kind: User
    name: exam-user
roleRef:
  kind: Role
  name: ns-view
  apiGroup: rbac.authorization.k8s.io
```

2) You're using a ServiceAccount without proper binding

Fix: bind the ServiceAccount to a Role or ClusterRole, or reference a ServiceAccount with sufficient rights in your Pod spec.

3) Mistaken context / kubeconfig

Check `kubectl config current-context` and `kubectl config view` to ensure you're targeting the correct cluster and user.

Exam tip
- Use `kubectl auth can-i` early in your troubleshooting to avoid wasting time chasing other problems.
