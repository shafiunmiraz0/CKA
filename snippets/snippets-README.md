# Snippets index

This folder contains quick, exam-friendly YAML snippets you can copy/paste during CKA practice and (if allowed) keep on your GitHub exam tab.

Files and purpose
- `deployment.yaml` — basic Deployment example
- `daemonset.yaml` — DaemonSet example
- `statefulset.yaml` — StatefulSet with volumeClaimTemplates
- `job.yaml` — batch Job example
- `cronjob.yaml` — CronJob example
- `hpa.yaml` — HorizontalPodAutoscaler example
- `service-clusterip.yaml` — ClusterIP Service
- `service-nodeport.yaml` — NodePort Service
- `service-externalname.yaml` — ExternalName Service
- `ingress-tls.yaml` — Ingress with TLS backend
- `networkpolicy-deny-allow.yaml` — NetworkPolicy allow pattern
- `pvc.yaml` — PersistentVolumeClaim example
- `pv-hostpath.yaml` — hostPath PersistentVolume (lab only)
- `storageclass.yaml` — StorageClass example
- `rbac-role-sa.yaml` — Role, RoleBinding, ServiceAccount (namespace-scoped)
- `clusterrole-clusterrolebinding.yaml` — ClusterRole & ClusterRoleBinding example
- `configmap-secret.yaml` — ConfigMap and Secret examples
- `initcontainers.yaml` — initContainers and lifecycle example
- `pod-securitycontext.yaml` — Pod securityContext (runAsUser, capabilities)
- `poddisruptionbudget.yaml` — PodDisruptionBudget example
- `resourcequota-limitrange.yaml` — ResourceQuota and LimitRange

How to use
- Open the file in your editor or on your allowed GitHub tab and copy the manifest you need.
- Keep filenames short and use `kubectl apply -f <file>` to quickly create resources.

Security note
- Some snippets use hostPath or cluster-level RBAC; these are for lab/exam practice only and are not recommended for production without review.
