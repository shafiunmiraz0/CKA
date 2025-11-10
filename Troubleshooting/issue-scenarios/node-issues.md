# Node Troubleshooting Scenarios

## Common Node Issues

### 1. Node NotReady State
**Symptoms:**
- Node status shows NotReady
- Pods on node not running
- Node unreachable

**Debugging Steps:**
```bash
# Check node status and conditions
kubectl describe node <node-name>

# Check kubelet status
systemctl status kubelet
journalctl -u kubelet -n 100

# Check kubelet certificates
openssl x509 -in /var/lib/kubelet/worker-1.crt -text -noout
```

### 2. Kubelet Issues
**Symptoms:**
- Kubelet service not running
- Node registration failures
- Pod operations failing

**Debugging Steps:**
```bash
# Check kubelet configuration
cat /var/lib/kubelet/config.yaml

# Verify kubelet process
ps aux | grep kubelet

# Check kubelet logs
journalctl -u kubelet -f

# Restart kubelet
systemctl restart kubelet
systemctl status kubelet
```

### 3. Container Runtime Issues
**Symptoms:**
- Container start failures
- Runtime errors in pod events
- Image pull issues

**Debugging Steps:**
```bash
# Check container runtime status
systemctl status containerd  # or docker
crictl info

# List containers and images
crictl ps -a
crictl images

# Check runtime logs
journalctl -u containerd  # or docker
```

### 4. Resource Pressure Issues
**Symptoms:**
- Node showing pressure conditions
- Pod evictions
- Resource exhaustion

**Debugging Steps:**
```bash
# Check node resource usage
kubectl top node <node-name>
kubectl describe node <node-name> | grep -A 5 Conditions

# Check system resources
df -h
free -m
top
```

### 5. Network Connectivity Issues
**Symptoms:**
- Node network unreachable
- Pod network issues
- CNI problems

**Debugging Steps:**
```bash
# Check CNI configuration
cat /etc/cni/net.d/*

# Verify network plugin pods
kubectl get pods -n kube-system -l k8s-app=calico-node  # or other CNI

# Test network connectivity
ping <node-ip>
traceroute <node-ip>
```

## Quick Reference Commands

```bash
# Node Status Commands
kubectl get nodes -o wide
kubectl describe node <node-name>
kubectl get node <node-name> -o yaml

# Kubelet Management
systemctl status kubelet
systemctl restart kubelet
journalctl -u kubelet -f

# Container Runtime Commands
crictl ps -a
crictl logs <container-id>
crictl inspect <container-id>

# Node Maintenance
kubectl drain <node-name> --ignore-daemonsets
kubectl cordon <node-name>
kubectl uncordon <node-name>

# Resource Usage
kubectl top node
df -h
free -m
top
```

## Example Configurations

### 1. Kubelet Configuration
```yaml
apiVersion: kubelet.config.k8s.io/v1beta1
kind: KubeletConfiguration
address: 0.0.0.0
port: 10250
serializeImagePulls: true
evictionHard:
  memory.available: "100Mi"
  nodefs.available: "10%"
  nodefs.inodesFree: "5%"
maxPods: 110
```

### 2. Node Problem Detector
```yaml
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: node-problem-detector
  namespace: kube-system
spec:
  selector:
    matchLabels:
      name: node-problem-detector
  template:
    metadata:
      labels:
        name: node-problem-detector
    spec:
      containers:
      - name: node-problem-detector
        image: k8s.gcr.io/node-problem-detector:v0.8.7
        securityContext:
          privileged: true
        volumeMounts:
        - name: log
          mountPath: /var/log
        - name: localtime
          mountPath: /etc/localtime
          readOnly: true
      volumes:
      - name: log
        hostPath:
          path: /var/log
      - name: localtime
        hostPath:
          path: /etc/localtime
```

### 3. Resource Monitoring Configuration
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: resource-monitor
spec:
  containers:
  - name: monitor
    image: gcr.io/google-containers/node-problem-detector:v0.8.7
    resources:
      limits:
        cpu: "200m"
        memory: "100Mi"
      requests:
        cpu: "100m"
        memory: "50Mi"
    volumeMounts:
    - name: log
      mountPath: /var/log
  volumes:
  - name: log
    hostPath:
      path: /var/log
```