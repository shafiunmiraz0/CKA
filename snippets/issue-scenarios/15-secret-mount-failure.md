# Scenario: Secret/ConfigMap not mounted or wrong key

Symptom
- Pod fails to start or the application reads empty/incorrect configuration. `kubectl describe pod` shows mount errors or the container logs show missing file/key.

Quick diagnostics
- kubectl describe pod <pod> -n <ns>
- kubectl get secret -n <ns> <secret> -o yaml
- kubectl get configmap -n <ns> <cm> -o yaml
- kubectl exec -it <pod> -n <ns> -- ls -la /path/where/mounted

Common causes & fixes

1) Secret in different namespace

Fix: Secrets and ConfigMaps must exist in the same namespace as the Pod. Create the secret in the target namespace.

2) Key name mismatch

Fix: check keys in the secret (`kubectl get secret mysecret -o jsonpath='{.data}'`) and update the mount or data key accordingly.

3) Volume mount path conflicts or permission issues

Fix: ensure the mountPath is correct and that the app expects the file name; check `subPath` usage.

Example: create secret and mount it

kubectl create secret generic mysecret --from-literal=config.json='{ "mode":"prod" }' -n myns

Pod snippet (mount secret):

```yaml
spec:
  containers:
  - name: app
    image: busybox:1.35.0
    volumeMounts:
    - name: cfg
      mountPath: /etc/config
  volumes:
  - name: cfg
    secret:
      secretName: mysecret
```
