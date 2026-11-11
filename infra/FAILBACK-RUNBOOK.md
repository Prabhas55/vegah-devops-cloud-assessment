# VEGAH DR Failback Runbook

## Objective

Restore Mumbai as the primary region after Singapore DR activation.

## Preconditions

- Mumbai EC2 and networking are healthy.
- Mumbai application dependencies are available.
- Singapore application is serving traffic.
- PostgreSQL data consistency has been verified.
- Failback is approved by the operator.

## Procedure

1. Announce the maintenance window.
2. Verify Mumbai infrastructure and application readiness.
3. Stop new writes and background workers in Singapore.
4. Check PostgreSQL replication status and final WAL positions.
5. Confirm that the data required for recovery is available in Mumbai.
6. Promote Mumbai PostgreSQL only after consistency checks.
7. Start Mumbai backend and worker services.
8. Verify Redis availability and pending job recovery.
9. Verify frontend, backend and NGINX health.
10. Restore normal primary-region traffic.
11. Verify DNS health checks.
12. Submit a test job and confirm successful completion.

## Validation

- PostgreSQL accepts writes in Mumbai.
- Backend health endpoint returns HTTP 200.
- Frontend returns HTTP 200.
- Redis responds to PING.
- Worker processes a test job successfully.
- DNS primary health check is healthy.

## Rollback

If validation fails, stop traffic changes and follow the incident recovery procedure.

Do not promote both databases or allow simultaneous independent writes.

## Important

Failback is a controlled manual process.
Do not execute database promotion without verifying replication
and data consistency.
