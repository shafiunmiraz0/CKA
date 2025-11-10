# Deployment with Secret

## Purpose
Show how to use Kubernetes Secrets with Deployments (environment variables and mounted secrets).

## Create a Secret
```bash
# Create a generic secret from literals
kubectl create secret generic app-secret --from-literal=username=admin --from-literal=password='S3cr3t!'

# Create from files
kubectl create secret generic tls-secret --from-file=tls.crt=path/to/tls.crt --from-file=tls.key=path/to/tls.key
```

## Deployment using Secret as env
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: secret-deploy
spec:
  replicas: 2
  selector:
    matchLabels:
      app: secret-app
  template:
    metadata:
      labels:
        app: secret-app
    spec:
      containers:
      - name: app
        image: nginx
        env:
        - name: DB_USER
          valueFrom:
            secretKeyRef:
              name: app-secret
              key: username
        - name: DB_PASS
          valueFrom:
            secretKeyRef:
              name: app-secret
              key: password
```

## Deployment mounting Secret as volume
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: secret-volume-deploy
spec:
  replicas: 1
  selector:
    matchLabels:
      app: secret-vol
  template:
    metadata:
      labels:
        app: secret-vol
    spec:
      containers:
      - name: app
        image: nginx
        volumeMounts:
        - name: tls
          mountPath: /etc/tls
          readOnly: true
      volumes:
      - name: tls
        secret:
          secretName: tls-secret
```

## Troubleshooting
- Secret not found: `kubectl get secret` in the same namespace.
- Mounted file empty: ensure `secretName` matches and pod restarted if secret was created after pod.
- Avoid encoding mistakes: `kubectl create secret` handles base64 for you; don't manually base64 when using create command.

## Exam tips
- Use `kubectl describe secret <name>` and `kubectl get secret <name> -o yaml` to inspect secrets.
- Avoid printing secret values in exam logs; use careful commands when necessary.
