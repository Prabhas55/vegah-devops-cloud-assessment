# Submission helper

## Video (3-4 min) - suggested script

| Time | Show | Say |
|---|---|---|
| 0:00-0:30 | Architecture diagram (`docs/DR.md`) | Two regions, streaming replication, Redis replica, Route 53 failover |
| 0:30-1:00 | Primary serving live traffic: open app, submit a job, `seed-jobs.sh`, `verify-data.sh snapshot` | Primary handles live traffic; this is the baseline data |
| 1:00-1:30 | Code: `compose.primary.yml`, `standby-entrypoint.sh`, `terraform/dns.tf` | WAL/replication config, slot, TLS, health check + failover records |
| 1:30-2:00 | Run `measure-rto.sh`, then `simulate-outage.sh` | Hard-killing every container on the primary |
| 2:00-3:00 | Route 53 flips, watchdog log, `failover.sh` output, app live on DR URL | Automatic promotion of Postgres and Redis, app tier starts |
| 3:00-3:40 | `verify-data.sh compare` -> DATA INTACT; new job completes on DR; measured RTO/RPO | Zero data loss, measured recovery time |

## Reply email (fill in the blanks)

Subject: Disaster Recovery Assessment Submission - Prabhas Nalajala

Hi Venkatesh,

Please find my Disaster Recovery & Business Continuity submission:

- GitHub repository: https://github.com/Prabhas55/vegah-devops-cloud-assessment (docs: `docs/DR.md`, `docs/RUNBOOK.md`)
- Walkthrough video: <LINK>
- Primary: AWS EC2 ap-south-1; DR: AWS EC2 ap-southeast-1 (Terraform)
- Replication: PostgreSQL streaming replication (TLS, slot, optional synchronous), Redis replica + AOF, hourly S3 backups
- Failover: Route 53 failover DNS with health check, automated promotion via watchdog script
- Measured RTO: <X> seconds | Measured RPO: <Y> (rows lost: <Z>)

Thank you,
Prabhas
