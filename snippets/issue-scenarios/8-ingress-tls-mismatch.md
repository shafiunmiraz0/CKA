# Scenario: Ingress TLS / certificate mismatch or secret not found

Symptom
- Ingress returns TLS handshake errors, browser warns about certificate, or `kubectl describe ingress` shows secret not found.

Quick diagnostics
- kubectl describe ingress <ingress> -n <ns>
- kubectl get secret -n <ns> | grep <tls-secret-name>
- kubectl logs -n <ingress-namespace> <ingress-controller-pod>  # check controller logs

Common causes & fixes

1) TLS Secret missing or wrong namespace

Fix: ensure the TLS secret exists in the same namespace as the Ingress (Ingress v1 requires secret in the same ns for many controllers).

Example: create TLS secret (replace base64 placeholders)

kubectl create secret tls my-tls-secret --cert=./tls.crt --key=./tls.key -n myns

2) Certificate hostname mismatch

Fix: ensure the cert's CN/SAN matches the Ingress host or reissue the certificate.

3) Ingress controller-specific annotations

Check controller docs (nginx-ingress, ingress-nginx, traefik) for required annotations and secret formats.

Quick test: temporarily remove tls stanza to confirm HTTP routing works:

kubectl patch ingress my-ingress -n myns --type='json' -p='[{"op":"remove","path":"/spec/tls"}]'
