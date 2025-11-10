# Scenario: Pod CrashLoopBackOff

Symptom
- Pod in CrashLoopBackOff, restarts repeatedly.

Quick diagnostics
- kubectl get pods -n <ns>
- kubectl describe pod <pod> -n <ns>    # look for events, OOMKilled, image errors
- kubectl logs <pod> -n <ns> --previous  # view previous container logs

Common causes & fixes

1) Application error / bad args

Fix: inspect logs, update container command or image.

Example: replace a bad image tag with a known good one on a Deployment

kubectl set image deploy/myapp myapp=myrepo/myapp:stable -n myns

2) Crash due to missing config (env, configmap, secret)

Fix: create the missing ConfigMap/Secret and patch the Deployment to mount or reference it.

Example ConfigMap + patch

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: myapp-config
  namespace: myns
data:
  MODE: "prod"
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: myapp
  namespace: myns
spec:
  template:
    spec:
      containers:
      - name: myapp
        image: myrepo/myapp:stable
        env:
        - name: MODE
          valueFrom:
            configMapKeyRef:
              name: myapp-config
              key: MODE
```

3) OOMKilled (insufficient memory)

Diagnosis: `kubectl describe pod` shows OOMKilled or `kubectl logs` truncated.

Fix: increase memory requests/limits or add resource limits to the Deployment.

Example patch:

kubectl patch deploy myapp -n myns --type='json' -p='[{"op":"replace","path":"/spec/template/spec/containers/0/resources","value":{"requests":{"cpu":"100m","memory":"256Mi"},"limits":{"cpu":"500m","memory":"512Mi"}}}]'

4) Init container failure

Check `kubectl describe pod` and `kubectl logs -c <init-container>` for the init container.

General exam tips
- Use `kubectl describe` first for events, then `kubectl logs` (previous) if CrashLoopBackOff.
- Use `kubectl apply -f` to apply fixed manifests, or `kubectl set image` / `kubectl patch` for quick edits.
