# Pod Issue Troubleshooting Scenario 1

## Issue: Pod Stuck in CrashLoopBackOff

**Symptoms:**
- Pod status shows `CrashLoopBackOff`
- Container repeatedly crashes and restarts
- Application not starting
- Repeated restart attempts visible in Pod age

**Root Causes:**
- Application process exiting with error code
- Missing or invalid configuration files
- Invalid command or arguments in Pod spec
- Insufficient file permissions
- Resource constraints causing OOM kills
- Missing environment variables or secrets

---

## Step 1: Initial Diagnosis

### Check Pod Status
```bash
# Get pod status summary
kubectl get pod <pod-name> -n <namespace>

# Get detailed pod information with events
kubectl describe pod <pod-name> -n <namespace>

# Check container status
kubectl get pod <pod-name> -o jsonpath='{.status.containerStatuses[0]}' | jq .
```

### Expected Output
```
NAME              READY   STATUS             RESTARTS   AGE
my-app            0/1     CrashLoopBackOff   5          2m15s

# Events section should show:
Type     Reason                 Age                From               Message
----     ------                 ----               ----               -------
Normal   Scheduled              2m30s              default-scheduler  Successfully assigned default/my-app to worker-node-1
Normal   Pulling                2m29s              kubelet            Pulling image "my-app:latest"
Normal   Pulled                 2m25s              kubelet            Successfully pulled image "my-app:latest"
Normal   Created                2m24s              kubelet            Created container my-app
Normal   Started                2m24s              kubelet            Started container my-app
Warning  BackOff                2m10s (x5 over 2m24s)  kubelet   Back-off restarting failed container
```

---

## Step 2: Check Application Logs

### View Current Logs
```bash
# Get recent logs (current attempt)
kubectl logs <pod-name> -n <namespace>

# Get previous logs (from last crash)
kubectl logs <pod-name> -n <namespace> --previous

# Get logs with timestamps
kubectl logs <pod-name> -n <namespace> --timestamps=true

# Get last 50 lines of logs
kubectl logs <pod-name> -n <namespace> --tail=50

# Stream logs in real-time (watch it crash)
kubectl logs <pod-name> -n <namespace> -f
```

### Common Log Patterns Indicating Issues

**Pattern 1: Application Error**
```
2024-12-05T10:00:00Z [ERROR] Failed to connect to database
2024-12-05T10:00:00Z [ERROR] connection refused on 127.0.0.1:5432
Exit code: 1
```

**Pattern 2: Configuration Not Found**
```
2024-12-05T10:00:00Z [ERROR] Configuration file /etc/config/app.yaml not found
Exit code: 1
```

**Pattern 3: Permission Denied**
```
2024-12-05T10:00:00Z [ERROR] Permission denied: /app/data
Exit code: 13
```

---

## Step 3: Check Container Exit Code

### Get Exit Code and Reason
```bash
# Get exit code from last terminated state
kubectl get pod <pod-name> -o jsonpath='{.status.containerStatuses[0].lastState.terminated.exitCode}'

# Get complete termination status
kubectl get pod <pod-name> -o jsonpath='{.status.containerStatuses[0].lastState.terminated}' | jq .

# Get reason for termination
kubectl get pod <pod-name> -o jsonpath='{.status.containerStatuses[0].lastState.terminated.reason}'
```

### Exit Code Reference
```
Exit Code 0:    Success (shouldn't crash if code is correct)
Exit Code 1:    General errors (application error, invalid argument)
Exit Code 2:    Misuse of shell command
Exit Code 127:  Command not found
Exit Code 128:  Invalid argument to exit
Exit Code 137:  OOM kill (code 128 + 9)
Exit Code 143:  Terminated by SIGTERM
Exit Code 255:  Exit status out of range
```

---

## Step 4: Verify Pod Configuration

### Check Command and Arguments
```bash
# Get pod spec for command/args
kubectl get pod <pod-name> -o jsonpath='{.spec.containers[0].command}'
kubectl get pod <pod-name> -o jsonpath='{.spec.containers[0].args}'

# Get full container spec
kubectl get pod <pod-name> -o jsonpath='{.spec.containers[0]}' | jq .

# Check environment variables
kubectl get pod <pod-name> -o jsonpath='{.spec.containers[0].env}' | jq .
```

### Test Pod YAML
```yaml
# Correct Pod Configuration
apiVersion: v1
kind: Pod
metadata:
  name: my-app
  namespace: default
spec:
  containers:
  - name: app
    image: my-app:latest
    command: ["/app/start.sh"]        # Valid command in image
    args: ["--config=/etc/config.yaml"]
    env:
    - name: DATABASE_URL
      valueFrom:
        secretKeyRef:
          name: db-secret
          key: url
    resources:
      requests:
        memory: "64Mi"
        cpu: "250m"
      limits:
        memory: "128Mi"
        cpu: "500m"
```

---

## Step 5: Common Fixes

### Issue: Application Code Error

**Diagnosis:**
```bash
# Logs show application exception
kubectl logs <pod-name> -n <namespace> --previous | grep -i exception
```

**Fix:**
```bash
# 1. Check image contains required runtime/dependencies
kubectl exec <pod-name> -n <namespace> -- ls -la /app/

# 2. Update application code and rebuild image
docker build -t my-app:v1.1 .
docker push my-app:v1.1

# 3. Update deployment
kubectl set image deployment/my-app my-app=my-app:v1.1 -n <namespace>

# 4. Verify new pods are running
kubectl get pods -n <namespace> --watch
```

### Issue: Invalid Command/Script

**Diagnosis:**
```bash
# Exit code 127 (command not found)
kubectl get pod <pod-name> -o jsonpath='{.status.containerStatuses[0].lastState.terminated.exitCode}'

# Logs show: "command not found"
kubectl logs <pod-name> -n <namespace> --previous | grep "not found"
```

**Fix:**
```yaml
# Incorrect Pod
spec:
  containers:
  - name: app
    image: ubuntu:20.04
    command: ["/app/start.sh"]  # ❌ This file doesn't exist in ubuntu image
    
# Correct Pod
spec:
  containers:
  - name: app
    image: my-app:latest  # ✓ Use image with the script included
    command: ["/app/start.sh"]
```

### Issue: Missing Environment Variable

**Diagnosis:**
```bash
# Logs show: "Environment variable X not set"
kubectl logs <pod-name> -n <namespace> --previous | grep -i "not set\|undefined"

# Check env vars defined in pod
kubectl get pod <pod-name> -o jsonpath='{.spec.containers[0].env}' | jq .
```

**Fix:**
```yaml
# Add missing env var
spec:
  containers:
  - name: app
    image: my-app:latest
    env:
    - name: DATABASE_URL          # ✓ Add this
      value: "postgresql://localhost:5432"
    - name: LOG_LEVEL
      valueFrom:
        configMapKeyRef:
          name: app-config
          key: log.level
```

### Issue: OOM Kill (Exit Code 137)

**Diagnosis:**
```bash
# Exit code 137
kubectl get pod <pod-name> -o jsonpath='{.status.containerStatuses[0].lastState.terminated.exitCode}'

# Reason will be "OOMKilled"
kubectl get pod <pod-name> -o jsonpath='{.status.containerStatuses[0].lastState.terminated.reason}'

# Check node memory
kubectl top nodes
kubectl describe node <node-name>
```

**Fix:**
```yaml
# Increase memory limit
spec:
  containers:
  - name: app
    image: my-app:latest
    resources:
      requests:
        memory: "512Mi"   # ✓ Increase from 256Mi
      limits:
        memory: "1Gi"     # ✓ Increase from 512Mi
```

---

## Step 6: Debug Container Execution

### Use Debug Pod to Verify Environment

**Create Debug Pod with Same Image**
```bash
# Create temporary debug pod with same image
kubectl run debug-app \
  --image=my-app:latest \
  --restart=Never \
  -it \
  -- /bin/sh

# Once inside, test the startup command
# Inside pod:
cd /app
ls -la
./start.sh --config=/etc/config.yaml
```

**Check File Permissions**
```bash
# From debug pod
ls -la /app/start.sh
# Output should show: -rwxr-xr-x (executable)

# If not executable:
chmod +x /app/start.sh
```

---

## Step 7: Apply Fix and Verify

### Restart the Pod
```bash
# Delete pod to force new attempt
kubectl delete pod <pod-name> -n <namespace>

# If pod is part of deployment, it auto-recreates
kubectl get pods -n <namespace> --watch

# Verify new pod status
kubectl get pod <pod-name> -n <namespace>
kubectl describe pod <pod-name> -n <namespace>
```

### Monitor Recovery
```bash
# Watch pod status transition
kubectl get pod <pod-name> -n <namespace> --watch

# Expected sequence:
# NAME     READY   STATUS              RESTARTS   AGE
# my-app   0/1     Pending             0          2s
# my-app   0/1     ContainerCreating   0          5s
# my-app   1/1     Running             0          10s

# Check logs are healthy
kubectl logs <pod-name> -n <namespace>
```

---

## Full Test Scenario

### Scenario: Pod with Missing Configuration File

**Problematic Pod:**
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: broken-app
spec:
  containers:
  - name: app
    image: my-app:latest
    command: ["/app/startup.sh"]
    args: ["--config=/etc/app/config.json"]  # ❌ ConfigMap not mounted!
    resources:
      requests:
        memory: "64Mi"
        cpu: "100m"
      limits:
        memory: "128Mi"
        cpu: "200m"
```

**Diagnostic Commands:**
```bash
# Step 1: Check pod status
kubectl describe pod broken-app

# Step 2: Check logs
kubectl logs broken-app --previous

# Output: "config file /etc/app/config.json not found"

# Step 3: Check if config file mounted
kubectl get pod broken-app -o jsonpath='{.spec.volumes}' | jq .

# Shows: No volumes mounted!
```

**Fixed Pod:**
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: app-config
data:
  config.json: |
    {
      "database": "postgresql://db:5432",
      "loglevel": "info"
    }

---
apiVersion: v1
kind: Pod
metadata:
  name: fixed-app
spec:
  containers:
  - name: app
    image: my-app:latest
    command: ["/app/startup.sh"]
    args: ["--config=/etc/app/config.json"]
    volumeMounts:
    - name: config
      mountPath: /etc/app
    resources:
      requests:
        memory: "64Mi"
        cpu: "100m"
      limits:
        memory: "128Mi"
        cpu: "200m"
  volumes:
  - name: config
    configMap:
      name: app-config
```

**Verification:**
```bash
# Apply fixed pod
kubectl apply -f fixed-app.yaml

# Verify it's running
kubectl get pod fixed-app
# Output: fixed-app   1/1     Running   0          15s

# Check logs are healthy
kubectl logs fixed-app
# Output: "App started successfully"
```

---

## CKA Exam Tips

- **Always check logs**: `kubectl logs <pod> --previous` is your first tool
- **Exit codes matter**: 0=success, 1=general error, 137=OOM, 127=command not found
- **Events tell story**: `kubectl describe pod` shows the sequence of events
- **Environment matters**: Check env vars, secrets, configmaps are properly mounted
- **Quick diagnosis**: `kubectl describe pod <pod> -n <ns>` often shows the problem immediately
- **Resource limits**: High exit code 137 = OOM, increase memory limits
- **Image verification**: Ensure image contains required files and executable permissions

---

## Quick Reference Commands

| Task | Command |
|------|---------|
| Check pod status | `kubectl describe pod <pod>` |
| View current logs | `kubectl logs <pod>` |
| View previous logs | `kubectl logs <pod> --previous` |
| Stream logs | `kubectl logs <pod> -f` |
| Get exit code | `kubectl get pod <pod> -o jsonpath='{.status.containerStatuses[0].lastState.terminated.exitCode}'` |
| Get termination reason | `kubectl get pod <pod> -o jsonpath='{.status.containerStatuses[0].lastState.terminated.reason}'` |
| Check env variables | `kubectl get pod <pod> -o jsonpath='{.spec.containers[0].env}' \| jq .` |
| Restart pod | `kubectl delete pod <pod>` |
| Watch pod recovery | `kubectl get pod <pod> --watch` |

---

## See Also
- Pod troubleshooting scenarios 2-8
- Deployment issue scenarios
- Pod logs and debugging patterns
- Resource limits and OOM issues
