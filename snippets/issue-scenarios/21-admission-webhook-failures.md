# Scenario: Admission webhook failures (mutating/validating webhooks)

Symptom
- Pod/Deployment creation fails with webhook errors: `admission webhook "..." denied the request` or timeouts contacting webhook.

Quick diagnostics
- kubectl get validatingwebhookconfigurations,mutatingwebhookconfigurations
- kubectl describe <resource> -n <ns> to capture exact error message
- kubectl logs -n kube-system <admission-webhook-pod> (if you run the webhook in-cluster)

Common causes & fixes

1) Webhook server unreachable or misconfigured

Fix: Ensure the webhook service is running and reachable. If webhook is external, ensure API server can reach it. For immediate exam workaround, you can disable the webhook (if allowed):

kubectl delete validatingwebhookconfiguration <name>

2) Webhook intentionally denies resource due to policy

Fix: Read the error to see which field caused denial; adjust pod spec to comply or update webhook config.

3) TLS / certificate issues between API server and webhook

Fix: Check webhook TLS configuration and CABundle in the webhook config; reconfigure CABundle if needed.

Exam tip
- Avoid disabling critical admission webhooks on production clusters. For exam/lab tasks where time is limited, temporarily disabling a non-essential webhook may be acceptable to proceed.
