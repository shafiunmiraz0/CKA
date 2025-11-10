# Workload Troubleshooting Scenarios

## Common Workload Issues

### 1. CronJob Issues
**Symptoms:**
- Jobs not executing on schedule
- Failed job executions
- Concurrent job conflicts

**Debugging Steps:**
```bash
# Check CronJob status
kubectl get cronjob
kubectl describe cronjob <cronjob-name>

# View job history
kubectl get jobs
kubectl get pods --selector=job-name=<job-name>

# Check job logs
kubectl logs job/<job-name>
```

**Example CronJob:**
```yaml
apiVersion: batch/v1
kind: CronJob
metadata:
  name: backup-job
spec:
  schedule: "0 1 * * *"
  concurrencyPolicy: Forbid
  successfulJobsHistoryLimit: 3
  failedJobsHistoryLimit: 1
  jobTemplate:
    spec:
      template:
        spec:
          containers:
          - name: backup
            image: backup-tool:latest
            command: ["/backup.sh"]
          restartPolicy: OnFailure
```

### 2. DaemonSet Issues
**Symptoms:**
- Pods not running on all nodes
- Update rollout problems
- Node selector mismatches

**Debugging Steps:**
```bash
# Check DaemonSet status
kubectl get daemonset
kubectl describe daemonset <daemonset-name>

# Verify pod distribution
kubectl get pods -o wide | grep <daemonset-name>

# Check node labels
kubectl get nodes --show-labels
```

**Example DaemonSet:**
```yaml
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: monitoring-agent
spec:
  selector:
    matchLabels:
      app: monitoring
  template:
    metadata:
      labels:
        app: monitoring
    spec:
      tolerations:
      - key: node-role.kubernetes.io/master
        effect: NoSchedule
      containers:
      - name: agent
        image: monitoring-agent:latest
```

### 3. StatefulSet Issues
**Symptoms:**
- Ordering problems
- Volume attachment issues
- Scale up/down failures

**Debugging Steps:**
```bash
# Check StatefulSet status
kubectl get statefulset
kubectl describe statefulset <statefulset-name>

# Verify PVC creation
kubectl get pvc -l app=<app-label>

# Check pod ordering
kubectl get pods -l app=<app-label> -o wide
```

### 4. Job Failures
**Symptoms:**
- Repeated job failures
- Backoff limit exceeded
- Resource constraints

**Debugging Steps:**
```bash
# Check job status
kubectl get jobs
kubectl describe job <job-name>

# View pod logs
kubectl logs -l job-name=<job-name>

# Check completion status
kubectl get pods --selector=job-name=<job-name>
```

## Quick Reference Commands

```bash
# CronJob Management
kubectl get cronjobs
kubectl create job --from=cronjob/<cronjob-name> <job-name>
kubectl delete cronjob <cronjob-name>

# DaemonSet Operations
kubectl rollout status daemonset/<daemonset-name>
kubectl rollout history daemonset/<daemonset-name>
kubectl rollout undo daemonset/<daemonset-name>

# StatefulSet Commands
kubectl scale statefulset <name> --replicas=<count>
kubectl get pvc -l app=<app-label>
kubectl delete statefulset <name> --cascade=false

# Job Control
kubectl create job <name> --image=<image>
kubectl delete job <name>
kubectl get jobs -o wide
```

## Common Configurations

### 1. Job with Retries
```yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: retry-job
spec:
  backoffLimit: 4
  template:
    spec:
      containers:
      - name: main
        image: busybox
        command: ["/bin/sh", "-c", "echo 'Processing...'; exit 1"]
      restartPolicy: OnFailure
```

### 2. StatefulSet with PVC
```yaml
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: web
spec:
  serviceName: "nginx"
  replicas: 3
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: nginx:1.14.2
        volumeMounts:
        - name: www
          mountPath: /usr/share/nginx/html
  volumeClaimTemplates:
  - metadata:
      name: www
    spec:
      accessModes: [ "ReadWriteOnce" ]
      resources:
        requests:
          storage: 1Gi
```

### 3. DaemonSet with Node Selector
```yaml
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: logging-agent
spec:
  selector:
    matchLabels:
      name: logging-agent
  template:
    metadata:
      labels:
        name: logging-agent
    spec:
      nodeSelector:
        type: production
      containers:
      - name: fluentd
        image: fluent/fluentd:v1.14
        resources:
          limits:
            memory: 200Mi
          requests:
            cpu: 100m
            memory: 200Mi
        volumeMounts:
        - name: varlog
          mountPath: /var/log
      volumes:
      - name: varlog
        hostPath:
          path: /var/log
```