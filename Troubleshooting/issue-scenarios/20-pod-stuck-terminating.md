# Scenario: Pod stuck in Terminating state

Symptom
- Pod remains in `Terminating` for a long time; `kubectl delete pod <pod>` doesn't remove it.

Quick diagnostics
- kubectl describe pod <pod> -n <ns>  # look at finalizers, deletionTimestamp, preStop hooks
- kubectl get pod <pod> -o yaml -n <ns>  # inspect metadata.finalizers and spec
- kubectl logs <pod> -n <ns> --previous

Common causes & fixes

1) Finalizers prevent deletion (PVC/PV or custom controllers)

Fix: If safe, remove finalizers from the resource YAML and apply. Example:

kubectl get pod <pod> -n <ns> -o json | jq '.metadata.finalizers = []' | kubectl apply -f -

2) Pod running a long preStop hook or container not terminating

Fix: Check container process and preStop hook. If necessary, force delete:

kubectl delete pod <pod> -n <ns> --grace-period=0 --force

3) API server or controller manager delays

Check control plane health and events: `kubectl get events -A --sort-by=.metadata.creationTimestamp`

Exam tip
- Use force delete as last resort in exam tasks when you need the resource cleared quickly and it's safe to do so.
