# Pod Logging Scenarios

## Scenario 1: Basic Log Retrieval

### Requirements
- Retrieve logs from a specific pod
- Filter logs by time
- Handle multi-container pods

### Solution
```bash
# Basic log retrieval
kubectl logs <pod-name>

# Logs from specific container in pod
kubectl logs <pod-name> -c <container-name>

# Logs with timestamp
kubectl logs <pod-name> --timestamps

# Last n lines of logs
kubectl logs <pod-name> --tail=100

# Logs since specific time
kubectl logs <pod-name> --since=1h
```

## Scenario 2: Log Streaming and Following

### Requirements
- Stream logs in real-time
- Follow logs for debugging
- Handle pod restarts

### Solution
```bash
# Stream logs in real-time
kubectl logs -f <pod-name>

# Stream logs with timestamp
kubectl logs -f <pod-name> --timestamps

# Follow logs from all containers
kubectl logs -f <pod-name> --all-containers

# Follow logs since specific time
kubectl logs -f <pod-name> --since=5m
```

## Scenario 3: Advanced Log Filtering

### Requirements
- Filter logs by specific patterns
- Handle multiple pods
- Export logs to file

### Solution
```bash
# Filter logs using grep
kubectl logs <pod-name> | grep "error"

# Logs from multiple pods with same label
kubectl logs -l app=myapp

# Export logs to file
kubectl logs <pod-name> > pod-logs.txt

# Filter by time range
kubectl logs <pod-name> --since-time="2023-01-01T00:00:00Z"
```

## Common Issues and Solutions

1. Pod logs not available
```bash
# Check pod status
kubectl describe pod <pod-name>

# Check previous container logs
kubectl logs <pod-name> --previous
```

2. Container crashes
```bash
# Get pod details
kubectl get pod <pod-name> -o yaml

# Check events
kubectl get events | grep <pod-name>
```

3. Log rotation
```bash
# Use --limit-bytes
kubectl logs <pod-name> --limit-bytes=100000

# Use --tail
kubectl logs <pod-name> --tail=1000
```

## Best Practices

1. Always use timestamps for debugging
2. Export important logs for analysis
3. Monitor log sizes and rotation
4. Use labels for efficient log filtering
5. Document common log patterns

## Verification Steps

1. Check log availability
```bash
# Verify pod is running
kubectl get pod <pod-name>

# Check log generation
kubectl logs <pod-name> --tail=1 -f
```

2. Verify log retention
```bash
# Check oldest available log
kubectl logs <pod-name> --since-time="2023-01-01T00:00:00Z" | head -n 1
```

3. Test log filters
```bash
# Test pattern matching
kubectl logs <pod-name> | grep -C 5 "ERROR"
```