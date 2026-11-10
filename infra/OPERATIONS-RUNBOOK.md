# VEGAH Operations and DR Readiness Runbook

## 1. Objective

This document provides operational procedures for monitoring
the VEGAH application and verifying disaster recovery readiness.

## 2. Regional Configuration

| Region | Role | AWS Region |
|---|---|---|
| Mumbai | Primary | ap-south-1 |
| Singapore | Secondary DR | ap-southeast-1 |

Mumbai serves normal application traffic. Singapore is maintained
as the secondary disaster recovery environment.

## 3. Daily Infrastructure Health Checks

Perform the following checks on the Mumbai primary EC2 instance.

### Check EC2 status

```bash
aws ec2 describe-instance-status \
  --region ap-south-1 \
  --instance-ids i-044897522a44948c4
```

### Check Docker containers

```bash
docker compose ps
```

### Check application logs

```bash
docker compose logs --tail=100 backend
docker compose logs --tail=100 worker
docker compose logs --tail=100 nginx
```

### Check application health

```bash
curl -i http://localhost/health
```

Confirm that the endpoint returns HTTP 200.

Note: The application health endpoint is a process-level health
check and does not independently verify every dependency.

## 4. PostgreSQL Monitoring

### Check database readiness

```bash
docker exec -it <postgres-container> \
  pg_isready -U vegah -d vegah_db
```

### Check primary replication status

Run inside the Mumbai PostgreSQL primary:

```sql
SELECT application_name,
       state,
       sync_state,
       sent_lsn,
       write_lsn,
       flush_lsn,
       replay_lsn
FROM pg_stat_replication;
```

Verify that the Singapore standby is connected and streaming.

### Check standby status

Run inside the Singapore PostgreSQL standby:

```sql
SELECT pg_is_in_recovery();
```

Expected standby result:

```text
t
```

Monitor replication lag and investigate disconnected or delayed
replication before considering the DR environment ready.

## 5. Redis Monitoring

### Check Redis availability

```bash
docker exec -it <redis-container> redis-cli PING
```

Expected response:

```text
PONG
```

### Check Redis persistence configuration

```bash
docker exec -it <redis-container> redis-cli INFO persistence
```

Review RDB and AOF configuration and persistence status.

Note: Mumbai and Singapore Redis instances are independent.
Continuous cross-region Redis synchronization is not configured.

## 6. Singapore DR Readiness Checks

Connect to the Singapore DR EC2 instance and verify:

```bash
docker ps -a
```

Check PostgreSQL standby status:

```bash
docker exec -it vegah-dr-postgres \
  psql -U vegah -d vegah_db \
  -c "SELECT pg_is_in_recovery();"
```

Check Redis:

```bash
docker exec -it vegah-dr-redis redis-cli PING
```

Check NGINX configuration:

```bash
docker exec -it <nginx-container> nginx -t
```

Verify that the DR environment remains in its intended standby
state. Do not start application services or promote the standby
during routine checks.

## 7. Application Validation

After an approved deployment or recovery operation, verify:

### Backend

```bash
curl -i http://localhost:3001/health
```

### Frontend

```bash
curl -I http://localhost
```

### NGINX

```bash
docker compose logs --tail=50 nginx
```

### Background worker

```bash
docker compose logs --tail=100 worker
```

Submit a test job and verify that it reaches COMPLETED status
before declaring end-to-end recovery successful.

## 8. Common Troubleshooting

| Issue | Investigation |
|---|---|
| Backend unavailable | Check backend logs and dependencies |
| PostgreSQL unhealthy | Check pg_isready and database logs |
| Replication disconnected | Inspect pg_stat_replication and network connectivity |
| Redis unavailable | Check Redis container and PING |
| Worker not processing | Inspect worker logs and queue state |
| NGINX unavailable | Run nginx -t and inspect logs |
| DR endpoint returns 503 | Check DR readiness state and backend status |

Do not delete persistent volumes as a troubleshooting shortcut.

## 9. Disaster Recovery Readiness Checklist

- [ ] Mumbai EC2 instance is healthy.
- [ ] Singapore EC2 instance is healthy.
- [ ] Mumbai application services are operational.
- [ ] Singapore PostgreSQL standby is connected.
- [ ] Replication lag is reviewed.
- [ ] Singapore Redis responds to PING.
- [ ] Required backups are available.
- [ ] DR failover script is present and permissions are correct.
- [ ] Route 53 health checks are healthy.
- [ ] Failover and failback runbooks are accessible.
- [ ] Operator approval process is documented.

## 10. Operational Safety

- Never promote both PostgreSQL instances independently.
- Prevent simultaneous writes to both regions.
- Verify replication and data consistency before failback.
- Stop new writes before controlled database role changes.
- Preserve existing database volumes and backups.
- Do not run Terraform apply against existing infrastructure
  without reviewing the execution plan and obtaining approval.
- Record all recovery actions and timestamps.

## 11. Related Documents

- `infra/ARCHITECTURE.md`
- `infra/DATA-RESILIENCE.md`
- `infra/DR-IMPLEMENTATION.md`
- `infra/DR-TEST-REPORT.md`
- `infra/FAILBACK-RUNBOOK.md`

