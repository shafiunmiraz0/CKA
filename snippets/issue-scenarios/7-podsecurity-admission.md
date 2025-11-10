# Scenario: Pod Security Admission denials

Symptom
- Pod creation is rejected with messages referencing PodSecurity, e.g. "denied by PodSecurity" or "forbidden: Pod violates the PodSecurity policy".

Quick diagnostics
- kubectl create -f <pod.yaml> -n <ns>  # capture the exact error
- kubectl get namespace <ns> -o yaml   # inspect pod-security labels: `pod-security.kubernetes.io/enforce`/`audit`/`warn`

Common causes & fixes

1) Namespace has stricter PodSecurity labels (restricted) than the Pod

Fix: either relax the namespace labels (if permitted) or change the Pod to comply.

Example: set namespace to `baseline` (if allowed by exam rules)

kubectl label namespace myns pod-security.kubernetes.io/enforce=baseline --overwrite

Or change Pod to comply: set `runAsNonRoot: true`, remove privileged containers, set `readOnlyRootFilesystem: true`.

Pod snippet (securityContext)

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: secured-pod
  namespace: myns
spec:
  containers:
  - name: app
    image: nginx:1.21
    securityContext:
      runAsNonRoot: true
      readOnlyRootFilesystem: true
```

2) Admission controllers enforce seccomp/AppArmor

Fix: use allowed seccomp profiles (`RuntimeDefault`), remove disallowed annotations, or change namespace policy.
