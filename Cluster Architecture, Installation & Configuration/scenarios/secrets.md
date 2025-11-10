# Secrets (Cluster Architecture, Installation & Maintenance)

## Purpose
Create and use Kubernetes Secrets; troubleshoot common issues. Useful for exam tasks that require storing credentials or TLS assets.

## Create Secrets
```bash
# Create from literal values
kubectl create secret generic app-secret --from-literal=username=admin --from-literal=password='S3cr3t!'

# Create from files
kubectl create secret generic tls-secret --from-file=tls.crt=./tls.crt --from-file=tls.key=./tls.key

# Create TLS secret
kubectl create secret tls my-tls --cert=./tls.crt --key=./tls.key

# Create from manifest (stringData easier to use in examples)
apiVersion: v1
kind: Secret
metadata:
  name: api-creds
type: Opaque
stringData:
  api-key: "my-api-key"
```

## Use Secrets
```yaml
# As environment variables in a Pod/Deployment
env:
- name: DB_USER
  valueFrom:
    secretKeyRef:
      name: app-secret
      key: username

# Mounted as files
volumes:
- name: secret-vol
  secret:
    secretName: tls-secret

volumeMounts:
- name: secret-vol
  mountPath: /etc/tls
  readOnly: true
```

## Inspect and Troubleshoot
```bash
# List secrets in namespace
kubectl get secrets

# Describe secret (shows metadata but not raw data)
kubectl describe secret app-secret

# View decoded secret data
kubectl get secret app-secret -o jsonpath='{.data.username}' | base64 --decode

# Common issue: Pod can't find secret
# - Ensure secret exists in the same namespace as the pod
kubectl get secret -n <namespace>

# Common issue: mounted file empty
# - Check secretName on volume, restart pod if secret created after pod
kubectl describe pod <pod-name>
```

## Best Practices
- Don't store secrets in plain text or commit to git
- Use `stringData` when creating secrets from YAML for readability
- Limit secret scope via namespaces and RBAC
- Rotate secrets regularly

## Exam tips
- Use `kubectl create secret` commands for speed during tasks
- Use `kubectl get secret <name> -o yaml` only when safe; it shows base64 values
