# Scenario: Missing ServiceAccount token / Pod cannot access API

Symptom
- Pod tries to access the API (in-cluster config) and fails with `403` or `Unauthorized` errors; logs show `serviceaccount "default" not found` or token mount missing.

Quick diagnostics
- kubectl describe pod <pod> -n <ns>    # look for mount events and volumes
- kubectl get sa -n <ns>
- kubectl get secret -n <ns> | grep <sa-name>

Common causes & fixes

1) `automountServiceAccountToken: false` set on ServiceAccount or pod

Fix: either set `automountServiceAccountToken: true` on the ServiceAccount or explicitly mount a token/Use a projected token. Example patch to SA:

kubectl patch sa default -n myns -p '{"automountServiceAccountToken": true}'

2) ServiceAccount missing or wrong name in Pod spec

Fix: ensure `serviceAccountName` in pod spec points to an existing ServiceAccount in the same namespace.

3) Token projected or bound to different name (Kubernetes 1.24+ changes)

Fix: for projected tokens, ensure pod uses the right token projection or use `kubectl create token <sa>` for testing.

Quick test
- Create a Pod using the SA and curl the API from inside the pod:

kubectl run -it --rm curlpod --image=radial/busyboxplus:curl --serviceaccount=default -- sh
# inside pod
curl -k https://kubernetes.default.svc/api | head -n 1
