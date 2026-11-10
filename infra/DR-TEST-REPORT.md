# VEGAH Disaster Recovery Test Report

## 1. Objective

Validate the disaster recovery architecture by simulating a
Mumbai primary-region outage, activating Singapore DR and
restoring normal operations in Mumbai.

## 2. Test Environment

| Component | Configuration |
|---|---|
| Primary region | Mumbai (ap-south-1) |
| Secondary region | Singapore (ap-southeast-1) |
| Primary database | PostgreSQL 16 |
| DR database | PostgreSQL 16 standby |
| Application | Docker Compose |
| Queue | Redis and BullMQ |
| Traffic management | AWS Route 53 |

## 3. Disaster Scenario

A controlled outage was simulated by stopping the Mumbai
PostgreSQL container.

The Singapore DR environment was then activated and application
services were brought online.

## 4. Failover Execution Timeline

| Event | Timestamp (UTC) |
|---|---|
| Mumbai PostgreSQL stopped | 12:38:25 |
| Singapore backend started | 12:39:34 |
| Singapore NGINX started | 12:44:58 |
| Singapore worker started | 12:46:45 |
| Test job completed successfully | 13:07:46 |

## 5. Recovery Time Objective (RTO)

Measured recovery time:

Approximately 29 minutes and 21 seconds.

Measurement started when the Mumbai PostgreSQL container stopped
and ended when a test job successfully completed in Singapore.

This represents the measured duration of this controlled test,
not a guaranteed production recovery time.

## 6. Recovery Point Objective (RPO)

PostgreSQL uses asynchronous streaming replication.

Potential data loss depends on replication lag and the last
successfully replayed WAL position at the time of failure.

An exact measured RPO was not established during this test.

Redis queue state has a separate recovery point because
continuous cross-region Redis synchronization is not configured.

## 7. Validation Results

| Validation | Result |
|---|---|
| Singapore PostgreSQL standby promotion | Completed |
| Singapore backend activation | Completed |
| Singapore frontend and NGINX activation | Completed |
| Singapore worker activation | Completed |
| End-to-end test job | Successful |
| Failback to Mumbai | Completed |

## 8. Test Job Evidence

Test job ID:

46f37342-55b6-41c8-9d69-cb2650a08087

The test job reached the COMPLETED state in the Singapore DR
environment.

## 9. Failback

After the DR test, the environment was restored to the original
architecture:

- Mumbai restored as the primary region.
- Singapore retained as the secondary DR region.
- Normal traffic routing restored to Mumbai.
- PostgreSQL consistency checked before primary restoration.

## 10. Limitations

- PostgreSQL replication is asynchronous.
- Exact RPO was not measured.
- Redis queue synchronization is not configured.
- DNS propagation time was not included in the measured RTO.
- The measured RTO does not represent the first successful
  public request.
- Additional automated backup and restore testing is required.

## 11. Conclusion

The controlled disaster recovery test demonstrated that the
Singapore secondary environment could be activated following
a simulated Mumbai database outage.

A background job was successfully processed in Singapore,
and failback to Mumbai was completed.

The measured recovery time was approximately 29 minutes
and 21 seconds.

Further improvements to Redis recovery, automated backups,
and exact RPO measurement are recommended.

