# Configuration & Access Troubleshooting Scenarios

## RBAC Issue: ServiceAccount Permission Denied

**Symptoms:**
- Pod logs show "forbidden" or "permission denied"
- kubectl commands fail with "error attempting to reach the server"
- ServiceAccount cannot perform required actions

## Quick Diagnosis
```bash
# Check if pod is using specific service account
kubectl get pod <pod-name> -o jsonpath='{.spec.serviceAccountName}'

# Check service account exists
kubectl get sa <sa-name> -n <namespace>

# Check associated role bindings
kubectl get rolebinding -n <namespace>
kubectl get clusterrolebinding

# Check if SA is in rolebinding
kubectl get rolebinding -n <namespace> -o yaml | grep <sa-name>

# Test specific permission
kubectl auth can-i get pods \
  --as=system:serviceaccount:<namespace>:<sa-name> \
  -n <namespace>

# Output: yes or no
```

## Common Causes & Fixes

### Cause 1: ServiceAccount Not Bound to Any Role
```bash
# Check for rolebindings with this SA
kubectl get rolebinding -n <namespace> \
  -o jsonpath='{.items[?(@.subjects[*].name=="<sa-name>")].metadata.name}'

# If empty, no role bound

# Create role
kubectl create role pod-reader \
  --verb=get,list,watch \
  --resource=pods \
  -n <namespace>

# Bind role to service account
kubectl create rolebinding read-pods \
  --role=pod-reader \
  --serviceaccount=<namespace>:<sa-name> \
  -n <namespace>

# Verify
kubectl auth can-i get pods \
  --as=system:serviceaccount:<namespace>:<sa-name> \
  -n <namespace>
# Output: yes
```

### Cause 2: Pod Using Default ServiceAccount
```bash
# Check what SA pod is using
kubectl get pod <pod-name> -o jsonpath='{.spec.serviceAccountName}'
# Output: default

# Verify default SA has permissions
kubectl get rolebinding -n <namespace> \
  -o jsonpath='{.items[?(@.subjects[*].name=="default")].metadata.name}'

# If default has no bindings, either:
# 1. Bind role to default SA, or
# 2. Create custom SA and update pod

# Option 1: Bind to default
kubectl create rolebinding read-pods \
  --role=pod-reader \
  --serviceaccount=<namespace>:default \
  -n <namespace>

# Option 2: Create custom SA
kubectl create serviceaccount app-sa -n <namespace>

# Edit pod to use new SA (requires recreate)
kubectl delete pod <pod-name> -n <namespace>

kubectl apply -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: <pod-name>
  namespace: <namespace>
spec:
  serviceAccountName: app-sa
  containers:
  - name: app
    image: nginx
EOF
```

### Cause 3: Role Missing Required Permissions
```bash
# Check what permissions role has
kubectl get role pod-reader -o yaml | grep -A 20 rules

# Example insufficient:
rules:
- apiGroups: [""]
  resources: ["pods"]
  verbs: ["get"]  # Missing "list"

# Check what pod needs
# App logs usually say: "unable to list pods"

# Fix role
kubectl edit role pod-reader -n <namespace>

# Add missing verbs:
rules:
- apiGroups: [""]
  resources: ["pods"]
  verbs: ["get", "list", "watch"]  # Added list, watch
```

### Cause 4: Wrong API Group or Resource
```bash
# Wrong API group example:
rules:
- apiGroups: ["v1"]  # ← Wrong (v1 is not an API group)
  resources: ["pods"]
  verbs: ["get"]

# Correct:
rules:
- apiGroups: [""]  # Empty = core API group
  resources: ["pods"]
  verbs: ["get"]

# For apps (Deployments):
rules:
- apiGroups: ["apps"]
  resources: ["deployments"]
  verbs: ["get", "list"]

# Check correct resource names
kubectl api-resources | grep -i deployment
# Shows: deployments (short name)
```

### Cause 5: ClusterRole Needed But Using Role
```bash
# Check if resource is cluster-scoped
kubectl api-resources --namespaced=false | grep -i node

# Nodes are cluster-scoped, need ClusterRole

# Check if using namespace role for cluster resource:
kubectl get role -n <namespace> -o yaml | grep resources

# Fix: Use ClusterRole instead
kubectl create clusterrole node-reader \
  --verb=get,list \
  --resource=nodes

kubectl create clusterrolebinding read-nodes \
  --clusterrole=node-reader \
  --serviceaccount=<namespace>:<sa-name>
```

## Recovery Process
```bash
# 1. Get pod's service account
SA=$(kubectl get pod <pod-name> -o jsonpath='{.spec.serviceAccountName}')

# 2. Test permissions
kubectl auth can-i get pods --as=system:serviceaccount:<namespace>:$SA -n <namespace>

# 3. If denied, check rolebindings
kubectl get rolebinding -n <namespace> -o yaml | grep $SA

# 4. Find what permissions needed (check app logs)
kubectl logs <pod-name> -n <namespace> | grep -i "unable\|forbidden\|permission"

# 5. Create or update role with needed permissions

# 6. Bind role to SA

# 7. Recreate pod if needed
# 8. Test again
```

---

## ServiceAccount Issue: Token Not Mounted

**Symptoms:**
- Pod cannot access Kubernetes API
- `/var/run/secrets/kubernetes.io/serviceaccount/` directory missing
- Pod cannot communicate with API server

## Diagnosis
```bash
# Check if SA token auto-mounted
kubectl get pod <pod-name> -o jsonpath='{.spec.automountServiceAccountToken}'

# Should be true by default

# Check inside pod
kubectl exec <pod-name> -n <namespace> -- ls -la /var/run/secrets/kubernetes.io/serviceaccount/

# Should show:
# ca.crt
# namespace
# token

# Check if files exist
kubectl exec <pod-name> -n <namespace> -- cat /var/run/secrets/kubernetes.io/serviceaccount/ca.crt

# If missing, check pod events
kubectl describe pod <pod-name> -n <namespace> | grep -A 10 "Events"
```

## Fix
```bash
# If automountServiceAccountToken is false, enable it

# For deployment:
kubectl patch deployment <name> \
  -p '{"spec":{"template":{"spec":{"automountServiceAccountToken":true}}}}'

# For pod (requires recreate):
kubectl delete pod <pod-name> -n <namespace>

# Reapply with:
apiVersion: v1
kind: Pod
metadata:
  name: <pod-name>
spec:
  automountServiceAccountToken: true  # ← Enable mounting
  serviceAccountName: <sa-name>
  containers:
  - name: app
    image: nginx
```

---

## Kubeconfig Issue: Cannot Connect to Server

**Symptoms:**
- `kubectl get nodes` fails
- Error: "Unable to connect to the server"
- "dial tcp: lookup on 0.0.0.0:53"

## Quick Diagnosis
```bash
# Check current context
kubectl config current-context

# Check kubeconfig contents
cat ~/.kube/config

# Verify server address
kubectl config view | grep server

# Test connectivity to server
curl -k https://<server-address>:6443

# Or use ping/nslookup
ping <server-address>
nslookup <server-address>
```

## Common Causes & Fixes

### Cause 1: Wrong Context Set
```bash
# List available contexts
kubectl config get-contexts

# Switch to correct context
kubectl config use-context <correct-context>

# Verify
kubectl config current-context
kubectl get nodes
```

### Cause 2: Server Address Invalid
```bash
# Check current server
kubectl config view | grep server

# Verify you can reach it
curl -k https://<server>:6443

# If unreachable, update context
kubectl config set-cluster <cluster-name> \
  --server=https://<correct-server>:6443 \
  --certificate-authority=<ca-file>

# Verify
kubectl get nodes
```

### Cause 3: Certificate/Auth Issues
```bash
# Check if using client certificate
kubectl config view | grep client-certificate

# Verify certificate is valid
openssl x509 -in ~/.kube/<cert-file> -noout -dates

# If expired, renew:
# - For kubeadm: kubeadm certs renew all
# - For custom setup: regenerate certificates

# Then update kubeconfig with new cert paths

kubectl config set-cluster <cluster-name> \
  --certificate-authority=<ca-file> \
  --embed-certs=true
```

### Cause 4: Authentication Token Expired
```bash
# Check auth method
kubectl config view | grep -E "user:|token|exec"

# If using token-based auth:
kubectl config set-credentials <user> \
  --token=<new-token>

# If using exec plugin (like AWS IAM):
# Verify plugin installed and credentials valid
aws sts get-caller-identity

# Update kubeconfig exec section if needed
```

### Cause 5: Proxy or Firewall Blocking
```bash
# Check if behind proxy
echo $HTTP_PROXY $HTTPS_PROXY

# If using proxy, configure kubectl
kubectl config set-cluster <cluster> \
  --proxy-url=http://<proxy>:8080

# Or use kubectl proxy
kubectl proxy --port=8080
# Then in another terminal:
kubectl get nodes --kubeconfig=<kubeconfig-no-cert>
```

## Recovery Process
```bash
# 1. Check current context
kubectl config current-context

# 2. Verify server address reachable
ping <server>

# 3. Check certificate validity
openssl x509 -in ~/.kube/<cert> -noout -dates

# 4. Verify authentication method
kubectl config view | grep -E "token|certificate|exec"

# 5. Test with verbose output
kubectl get nodes -v=8

# 6. Fix based on error messages

# 7. Verify access restored
kubectl get nodes
```

---

## Kubectl Port-Forward Not Working

**Symptoms:**
- `kubectl port-forward` command hangs or fails
- "Unable to establish a port forward" error
- Port forward stops working after some time

## Diagnosis
```bash
# Test port-forward
kubectl port-forward svc/<service-name> 8080:80 -n <namespace>

# If hangs, check service
kubectl get svc <service-name> -n <namespace>

# Check if endpoints exist
kubectl get endpoints <service-name> -n <namespace>

# Check if pods running
kubectl get pods -n <namespace>

# Try to access service from pod
kubectl run -it debug --image=curlimages/curl --rm -n <namespace> -- sh
# Inside: curl http://<service-name>:80
```

## Common Causes & Fixes

### Cause 1: Service Has No Endpoints
```bash
# Check endpoints
kubectl get endpoints <service-name> -n <namespace>

# If empty or none, check pods
kubectl get pods -n <namespace> -l <selector>

# If no pods match selector, fix selector:
kubectl get svc <service-name> -o yaml | grep selector

# Verify pods have matching labels
kubectl get pods --show-labels -n <namespace>

# If labels don't match, either:
# 1. Add labels to pod
# 2. Update service selector

# Update selector:
kubectl patch svc <service-name> -p '{"spec":{"selector":{"app":"correct-app"}}}'
```

### Cause 2: Firewall Blocking Port
```bash
# Windows firewall might block port

# Temporarily disable:
# On Windows, run as admin:
# netsh advfirewall set allprofiles state off

# Or use different port
kubectl port-forward svc/<service-name> 9999:80

# Then access: localhost:9999
```

### Cause 3: Port Already in Use
```bash
# Check if port already listening
netstat -tlnp | grep 8080
# or on Windows:
netstat -an | findstr 8080

# If port in use, use different port:
kubectl port-forward svc/<service-name> 9090:80
```

### Cause 4: Pod Not Ready
```bash
# Check pod status
kubectl get pod <pod-name> -n <namespace>

# Should be Running and all containers Ready

# If not ready:
kubectl describe pod <pod-name> -n <namespace>

# Check for readiness probe issues
# (See Pod troubleshooting scenarios)
```

## Recovery Process
```bash
# 1. Verify service exists
kubectl get svc <service-name> -n <namespace>

# 2. Check service has endpoints
kubectl get endpoints <service-name> -n <namespace>

# 3. Verify pods behind service are running
kubectl get pods -n <namespace> -l <selector>

# 4. Check ports match
kubectl get svc <service-name> -o yaml | grep -A 3 ports

# 5. Try port-forward with verbose
kubectl port-forward -v=8 svc/<service-name> 8080:80

# 6. If OK, access from browser/curl:
curl http://localhost:8080
```

---

## Quick Reference: Config & Access Issues

| Issue | Command to Check | Common Fix |
|-------|------------------|-----------|
| Permission denied | `kubectl auth can-i` | Bind role to service account |
| Token not mounted | `kubectl get pod -o yaml` | Enable automountServiceAccountToken |
| Cannot connect | `kubectl config view` | Switch context or fix server address |
| Cert expired | `openssl x509 -dates` | Renew certificates |
| Port-forward hangs | `kubectl get endpoints` | Fix service selector or start pods |
| Wrong context | `kubectl config current-context` | `kubectl config use-context` |

---

## CKA Exam Tips

- **ServiceAccount default**: Each namespace has default SA, used by pods by default
- **Token location**: Always `/var/run/secrets/kubernetes.io/serviceaccount/`
- **Role vs ClusterRole**: Use ClusterRole for cluster-scoped resources (nodes, namespaces)
- **RoleBinding subjects**: Must specify kind (ServiceAccount), name, and namespace
- **Auth can-i**: Great for testing permissions before running actual command
- **Kubeconfig structure**: contexts, clusters, users - all must be set correctly
- **Port-forward usefulness**: Great for testing services during troubleshooting
- **Certificates**: Know how to check expiry with openssl

---

## See Also
- RBAC best practices
- Service account design patterns
- Kubeconfig management
- Network policies and access control
