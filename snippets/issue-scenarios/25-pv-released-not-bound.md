# Scenario: PV shows Released state but PVC not bound / reclaim issues

Symptom
- PV is `Released` and not reclaimed; new PVCs requesting same storage class don't bind to it.

Quick diagnostics
- kubectl get pv
- kubectl describe pv <pv-name>
- kubectl get pvc -A

Common causes & fixes

1) PV `reclaimPolicy` is `Retain` and manual cleanup is required

Fix: Manually clean the data on the volume and then either delete the PV and create a new one or change the PV's reclaim policy and re-provision.

Example: mark PV as Available (advanced)

kubectl patch pv <pv-name> -p '{"metadata":{"finalizers":[]}}'  # remove finalizers (if safe)
kubectl delete pv <pv-name>
# then create a reclaimed PV manifest or allow a dynamic provisioner to satisfy the PVC

2) PV and PVC selectors (storageClass, labels) don't match

Fix: Ensure PVC's `storageClassName` and accessModes match the PV, or create a PV with matching attributes.

Exam tip
- For exam tasks, it's often faster to create a new hostPath PV that satisfies the PVC rather than trying to recover an existing PV unless the task explicitly requires PV recovery.
