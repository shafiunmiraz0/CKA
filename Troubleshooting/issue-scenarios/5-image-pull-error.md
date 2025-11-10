# Scenario: ImagePullBackOff / ErrImagePull

Symptom
- Pod shows `ImagePullBackOff` or `ErrImagePull` in `kubectl get pods` and `kubectl describe pod` shows pull errors.

Quick diagnostics
- kubectl describe pod <pod> -n <ns>    # check image and events
- kubectl get events -n <ns> --sort-by='.lastTimestamp'

Common causes & fixes

1) Wrong image name or tag

Fix: correct the image and update the Deployment

kubectl set image deploy/myapp myapp=myrepo/myapp:stable -n myns

2) Private registry requires imagePullSecret

Create imagePullSecret and attach it to the ServiceAccount or pod.

Create secret:

kubectl create secret docker-registry regcred --docker-server=myregistry.example.com --docker-username=USER --docker-password=PASS -n myns

Patch a Deployment to use the secret (attach to serviceAccount or pod spec):

kubectl patch deploy myapp -n myns --type='json' -p='[{"op":"add","path":"/spec/template/spec/imagePullSecrets","value":[{"name":"regcred"}]}]'

Alternatively, create a ServiceAccount and use it:

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: private-sa
  namespace: myns
imagePullSecrets:
  - name: regcred
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: myapp
  namespace: myns
spec:
  template:
    spec:
      serviceAccountName: private-sa
      containers:
      - name: myapp
        image: myregistry.example.com/myorg/myapp:stable
```

3) Registry TLS / DNS issues

Check that nodes can resolve and reach the registry (requires node access). For quick exam debugging, confirm correct registry hostname and credentials.
