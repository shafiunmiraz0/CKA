# Scenario: PVC stuck in Terminating due to finalizer

Symptom
- PersistentVolumeClaim remains in `Terminating` state; `kubectl describe pvc` shows finalizers or events related to reclaim policy.

Quick diagnostics
- kubectl get pvc <pvc> -n <ns> -o yaml
- kubectl get pv -o wide
- kubectl describe pv <pv>

Common causes & fixes

1) Finalizers on PVC or PV preventing garbage collection

Fix: If PV/PVC are safe to remove, edit the resource to remove finalizers. Example:

kubectl get pvc <pvc> -n <ns> -o json | jq '.metadata.finalizers = []' | kubectl apply -f -

2) PV still bound or reclaim policy preventing deletion

Fix: Check PV `status.phase` and `spec.persistentVolumeReclaimPolicy`. If reclaim policy is `Retain`, manually delete the PV after ensuring data is handled.

Exam tip
- Be careful removing finalizers; prefer to understand why the finalizer exists (cleanup controller, snapshot controller) before removing it.
