# VEGAH Disaster Recovery Implementation

## 1. Project Overview

This project implements a disaster recovery environment for the
VEGAH application using AWS Mumbai as the primary region and
AWS Singapore as the secondary DR region.

- Primary Region: ap-south-1 (Mumbai)
- DR Region: ap-southeast-1 (Singapore)
- Application: VEGAH Job Manager
- Database: PostgreSQL 16
- Cache and Queue: Redis
- Containerization: Docker and Docker Compose
- Infrastructure as Code: Terraform
- Configuration Management: Ansible
- DNS Failover: Amazon Route 53

## 2. Disaster Recovery Architecture

The Mumbai environment handles normal application traffic.

The Singapore environment maintains a PostgreSQL standby database
and provides a secondary application environment.

During a primary-region outage, the DR procedure promotes the
Singapore PostgreSQL standby and activates the application services.

## 3. PostgreSQL Replication

PostgreSQL streaming replication is configured between Mumbai
(primary) and Singapore (standby).

Replication configuration includes:

- Primary PostgreSQL server in Mumbai.
- Standby PostgreSQL server in Singapore.
- WAL-based streaming replication.
- Dedicated replication user.
- PostgreSQL replication slot.
- Replay and replication status verification.

Replication uses asynchronous mode. Therefore, a non-zero RPO
is possible if the primary fails before the latest WAL changes
reach the standby.

## 4. Redis Data Considerations

Redis runs independently in both regions.

Redis persistence data is maintained using a Docker volume.
Redis data is not continuously replicated between the two regions.

The recovery procedure must account for possible loss of
in-memory queue data and verify pending jobs after failover.

## 5. DNS Failover

Amazon Route 53 is configured with failover routing:

- Mumbai: PRIMARY
- Singapore: SECONDARY
- Health checks monitor the application health endpoint.
- DNS TTL: 60 seconds.

The DR environment remains unavailable to health checks while
it is in standby mode. Its readiness endpoint becomes healthy
after successful activation.

## 6. Automated Failover

The Singapore failover script performs these checks and actions:

1. Checks Mumbai application and database connectivity.
2. Confirms that the Singapore database is in standby mode.
3. Stops the Mumbai EC2 instance after outage confirmation.
4. Promotes the Singapore PostgreSQL standby.
5. Verifies that PostgreSQL accepts writes.
6. Checks Redis availability.
7. Starts the backend, frontend, NGINX and worker services.
8. Enables the DR readiness endpoint.
9. Verifies application health.

The script supports dry-run mode. Actual execution requires
the explicit --execute argument.

## 7. Failback

Failback is a controlled procedure.

1. Stop application writes and workers in Singapore.
2. Verify database consistency and replication position.
3. Prepare Mumbai PostgreSQL as the new primary.
4. Promote Mumbai when safe.
5. Start Mumbai application services.
6. Verify application and worker functionality.
7. Restore normal primary-region traffic.

Failback is not an automatic reverse of the failover script.

## 8. DR Test Results

A controlled failover and failback exercise was performed.

The final end-to-end DR test successfully processed a job.

Recorded test evidence:

- Database outage timestamp: 12:38:25 UTC
- Singapore backend started: 12:39:34 UTC
- Singapore NGINX started: 12:44:58 UTC
- Singapore worker started: 12:46:45 UTC
- Successful job completion: 13:07:46 UTC

Measured elapsed time from the recorded database outage
to successful job completion: approximately 29 minutes 21 seconds.

This is a test measurement, not a guaranteed production RTO.
It does not measure the first successful public request or
DNS propagation time.

## 9. RTO and RPO

RTO:
Approximately 29 minutes 21 seconds in the recorded test.

RPO:
Potentially non-zero because PostgreSQL replication is asynchronous.
The actual data loss depends on the last WAL position received
and replayed by the standby when the primary fails.

Redis queue recovery also requires separate verification.

## 10. Repository Structure

- infra/terraform: DR infrastructure definitions.
- infra/ansible: DR server verification and configuration.
- backend: Application backend.
- frontend: Application frontend.
- worker: Background job worker.
- database: Database-related files.
- nginx: Reverse proxy configuration.

## 11. Important Limitations

- Redis does not have continuous cross-region replication.
- PostgreSQL asynchronous replication can result in data loss.
- Application health endpoints do not independently verify
  all database and Redis dependencies.
- Worker container status does not prove successful job processing.
- DNS propagation can add time to recovery.
- Failback requires a controlled manual procedure.

## 12. Conclusion

The project demonstrates a multi-region disaster recovery
architecture using AWS, PostgreSQL streaming replication,
Docker, Terraform, Ansible and Route 53.

The implementation includes standby database verification,
controlled failover, application recovery and end-to-end job testing.
