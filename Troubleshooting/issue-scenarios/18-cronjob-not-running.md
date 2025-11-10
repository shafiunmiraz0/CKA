# Scenario: CronJob not running / missed schedules

Symptom
- CronJob doesn't create Jobs at the expected schedule; `kubectl get cronjob` shows lastSchedule empty or older than expected.

Quick diagnostics
- kubectl get cronjob -n <ns>
- kubectl describe cronjob <cronjob> -n <ns>
- kubectl get jobs -n <ns> --selector=job-name

Common causes & fixes

1) CronJob suspended

Fix: check `suspend` field in CronJob spec. Resume with:

kubectl patch cronjob <name> -n <ns> -p '{"spec":{"suspend":false}}'

2) Schedule syntax invalid

Fix: check the `schedule` field (cron format). Use `*/5 * * * *` or a valid cron expression.

3) StartingDeadlineSeconds / concurrencyPolicy preventing runs

If the CronJob misses the window due to StartinDeadlineSeconds or concurrencyPolicy set to Forbid and a previous job still running, it won't start.

Fix: adjust `startingDeadlineSeconds` or `concurrencyPolicy` (Allow) if appropriate.

4) Time/Timezone mismatch (control plane vs expectation)

Fix: CronJobs use control plane time; verify schedule relative to control plane timezone.

Quick fixes
- Temporarily create a Job from the jobTemplate to test the template:

kubectl create job --from=cronjob/<cronjob-name> manual-run -n <ns>
