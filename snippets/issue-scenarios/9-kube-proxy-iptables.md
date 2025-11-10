# Scenario: kube-proxy / iptables networking issues

Symptom
- Services return connection refused, or pods can't reach services; `kubectl get pods -n kube-system` shows kube-proxy pod CrashLoopBackOff or NotReady.

Quick diagnostics
- kubectl -n kube-system get pods -l k8s-app=kube-proxy
- kubectl logs -n kube-system <kube-proxy-pod>
- On node: `iptables -L -n -t nat | grep KUBE-SVC` (requires node access)

Common causes & fixes

1) kube-proxy not running or misconfigured

Fix: check kube-proxy logs, restart the DaemonSet or fix config. If using iptables mode ensure kernel modules are available.

kubectl rollout restart daemonset/kube-proxy -n kube-system

2) iptables rules missing (node-level issues)

Fix: investigate node OS (conntrack, iptables). Restart kube-proxy after fixing kernel modules or iptables rules.

3) CNI interfering with kube-proxy

Check CNI plugin compatibility and restart CNI pods if necessary.

Exam tip
- If you can't access nodes, try using a pod to curl service IPs and cluster IPs to narrow whether the issue is node-level or kube-proxy/service-level.
