# VEGAH Database and Data Resilience Strategy

## 1. Objective

This document describes the database replication, data recovery,
backup considerations and limitations of the VEGAH multi-region
disaster recovery architecture.

## 2. Regional Architecture

| Region | Role | Database |
|---|---|---|
| Mumbai (ap-south-1) | Primary | PostgreSQL 16 |
| Singapore (ap-southeast-1) | Secondary DR | PostgreSQL 16 standby |

Mumbai is the primary region. Singapore is the secondary disaster
recovery region.

## 3. PostgreSQL Replication

PostgreSQL asynchronous streaming replication is configured
between Mumbai and Singapore.

- Mumbai PostgreSQL operates as the primary database.
- Singapore PostgreSQL operates as a standby replica.
- WAL records are streamed from Mumbai to Singapore.
- Singapore remains read-only while operating as a standby.
- During failover, Singapore PostgreSQL is promoted after
  replication and consistency checks.
- During failback, data consistency is verified before Mumbai
  is restored as the primary database.

### Replication Validation

Run the following command on the primary database:

```sql
SELECT application_name, state, sync_state,
       sent_lsn, write_lsn, flush_lsn, replay_lsn
FROM pg_stat_replication;
```

Run the following command on the standby database:

```sql
SELECT pg_is_in_recovery();
```

Expected standby result:

```text
t
```

After promotion, verify that the database accepts writes.

## 4. Redis and Queue Data Recovery

Redis is used by BullMQ for background job queue management.

Current architecture:

- Mumbai and Singapore have separate Redis instances.
- Continuous Redis replication between regions is not configured.
- PostgreSQL replication does not replicate Redis queue state.
- Pending and in-progress jobs may require recovery or resubmission
  after a regional failure.

### Recovery Recommendations

For production-grade recovery:

1. Enable Redis persistence using AOF and/or RDB snapshots.
2. Back up Redis persistence files to durable storage.
3. Copy backups to a separate region.
4. Define a documented restore procedure.
5. Validate pending, completed and failed job states.
6. Design application-level job reconciliation to prevent
   duplicate processing.

These are recommended improvements and should not be considered
implemented until configured and tested.

## 5. Persistent Volume Backup Strategy

PostgreSQL data is stored in persistent Docker volumes.

Recommended backup practices:

- Perform regular PostgreSQL logical backups using pg_dump.
- Store backups in encrypted durable storage.
- Copy backups to a separate AWS region.
- Retain backups according to a defined retention policy.
- Test restoration periodically.
- Protect backups with restricted IAM permissions.

An EBS snapshot has been created for the Singapore DR instance.
A snapshot alone does not establish automated database backup
scheduling or a tested point-in-time recovery process.

## 6. Recovery Point Objective (RPO)

PostgreSQL replication is asynchronous.

Therefore, transactions committed in Mumbai may not yet have
reached Singapore when an unexpected outage occurs.

The potential data loss depends on replication lag and the last
successfully replayed WAL position.

An exact measured RPO has not been established.

Redis queue recovery has a separate recovery point because
continuous cross-region Redis synchronization is not configured.

## 7. Recovery Time Objective (RTO)

A controlled Mumbai-to-Singapore failover test was performed.

Measured recovery time:

Approximately 29 minutes and 21 seconds.

Measurement started when the Mumbai PostgreSQL container stopped
and ended when a test job successfully completed in Singapore.

This is a measured test result, not a guaranteed production RTO.

## 8. Recovery Validation Checklist

- [ ] Verify PostgreSQL replication and WAL positions.
- [ ] Confirm the promoted database accepts writes.
- [ ] Verify Redis responds to PING.
- [ ] Check pending and in-progress job recovery.
- [ ] Verify backend health endpoint.
- [ ] Verify frontend availability.
- [ ] Verify NGINX health.
- [ ] Submit a test job.
- [ ] Confirm successful worker processing.
- [ ] Verify traffic routing and DNS health checks.

## 9. Current Limitations

- PostgreSQL replication is asynchronous.
- Exact RPO has not been measured.
- Continuous Redis cross-region synchronization is not configured.
- Automated Redis backup and restore are not yet validated.
- Automated PostgreSQL point-in-time recovery is not yet validated.
- Backup restoration procedures require further testing.

## 10. Conclusion

The VEGAH architecture provides PostgreSQL asynchronous
cross-region replication and a tested regional failover and
failback process.

Redis synchronization, automated backup scheduling and
point-in-time recovery are identified as further improvements
for production-grade data resilience.
