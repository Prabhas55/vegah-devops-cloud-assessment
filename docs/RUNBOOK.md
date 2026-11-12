# DR Runbook

Hosts: **PRIMARY** = existing EC2 (ap-south-1), **DR** = Terraform-provisioned EC2 (ap-southeast-1).
All scripts live in `~/vegah-devops-cloud-assessment/scripts` on each host. Use **alphanumeric** secrets (they are sourced from `.env`).

## 0. Prerequisites (once)

1. Attach an **Elastic IP** to the primary (a stopped/restarted instance otherwise loses its public IP). Use that IP everywhere below.
2. Install `jq` on the primary: `sudo apt-get install -y jq` (optional, for `seed-jobs.sh`).
3. Optional DNS failover: have a public Route 53 hosted zone (`domain_name`).
4. Merge this branch to `main`. CI builds and deploys the new images (Redis password support + DB-aware `/api/health`). Verify the app still works at the primary URL.

## 1. One-time setup (order matters)

**A. Provision the DR site (laptop)**
```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars   # edit values
terraform init
terraform plan
terraform apply
# note: dr_public_ip, backup_bucket
```

**B. Enable replication on the PRIMARY**
```bash
ssh ubuntu@PRIMARY_IP
cd ~/vegah-devops-cloud-assessment && git pull
# add to .env (same values must be used on the DR host):
#   REDIS_PASSWORD=...  REPLICATION_PASSWORD=...  (see .env.example)
./scripts/primary-enable-replication.sh DR_PUBLIC_IP PRIMARY_PUBLIC_IP
curl -fsS http://localhost/api/health
```
If you did not give Terraform `primary_sg_id`, add inbound rules on the primary security group: TCP 5432 and 6379 from `DR_PUBLIC_IP/32`.

**C. Build the DR standby**
```bash
ssh ubuntu@DR_PUBLIC_IP
ls /var/log/vegah-bootstrap.done            # bootstrap finished?
cd ~/vegah-devops-cloud-assessment && git pull
echo "$GHCR_TOKEN" | docker login ghcr.io -u Prabhas55 --password-stdin   # token with read:packages
cp .env.example .env && nano .env           # SAME DB/Redis/replication secrets as primary
#   PRIMARY_HOST=PRIMARY_PUBLIC_IP   BACKUP_BUCKET=<terraform output>   AUTO_FAILOVER=true
./scripts/dr-setup.sh
```

**D. Zero-data-loss mode (on the PRIMARY)**
```bash
./scripts/enable-sync-replication.sh on     # RPO = 0 (writes wait for the standby)
# ./scripts/enable-sync-replication.sh off  # async if the standby will be down for long
```

**E. Check replication**
```bash
# primary
docker compose exec -u postgres postgres psql -U vegah_user -d vegah_db -c "SELECT application_name,state,sync_state,sent_lsn,replay_lsn FROM pg_stat_replication;"
# DR
docker compose exec -u postgres postgres psql -U vegah_user -d vegah_db -c "SELECT pg_is_in_recovery();"   # t
docker compose exec redis redis-cli info replication | grep master_link_status               # up
```

## 2. Disaster drill (demo)

Laptop terminal 1 (keep visible in the video):
```bash
./scripts/measure-rto.sh http://app.example.com/api/health app.example.com
```
Laptop terminal 2:
```bash
./scripts/seed-jobs.sh http://app.example.com 5      # data on primary
./scripts/verify-data.sh snapshot http://app.example.com
```
Kill the primary (on the primary host, or Actions -> DR Drill -> `simulate-outage`):
```bash
./scripts/simulate-outage.sh
```
What happens (watch terminal 1 and `journalctl -u dr-watchdog -f` on DR):
1. Route 53 health check fails (~30s) and DNS answers switch to the DR IP.
2. The watchdog reaches its threshold and runs `failover.sh`: promotes Postgres (`pg_promote`), promotes Redis (`REPLICAOF NO ONE`), starts the app tier, waits for `/api/health`.
3. `measure-rto.sh` prints `>>> MEASURED RTO: N seconds`.

Verify (laptop):
```bash
./scripts/verify-data.sh compare http://app.example.com   # RESULT: DATA INTACT
./scripts/seed-jobs.sh http://app.example.com 2           # new writes work on DR
```
Manual failover (if `AUTO_FAILOVER=false`): on the DR host run `./scripts/failover.sh`.

## 3. Failback to the original primary

Prerequisite: the original host is reachable again. **Do not** start its old stack (split-brain) - the script wipes and re-seeds it.

From the laptop (or Actions -> DR Drill -> `failback`):
```bash
export PRIMARY_IP=... DR_IP=... SSH_KEY_PRIMARY=~/.ssh/primary.pem SSH_KEY_DR=~/.ssh/dr.pem
./scripts/failback.sh
```
Steps performed: re-seed the original as a standby of DR, wait for lag 0, stop the DR app (brief write freeze), final catch-up, promote the original with the full stack, re-seed DR as its standby. Route 53 returns traffic to the primary when its health check passes. Finally re-enable sync mode on the primary: `./scripts/enable-sync-replication.sh on`.

## 4. Troubleshooting

| Symptom | Check |
|---|---|
| Standby never connects | primary SG allows 5432 from DR IP; `pg_hba.conf` has the `hostssl replication replicator DR_IP/32` line; same `REPLICATION_PASSWORD` on both |
| Writes hang on primary | sync mode on but standby down: `./scripts/enable-sync-replication.sh off` |
| `redis` master_link_status down | `REDIS_PASSWORD` mismatch, or SG blocks 6379 |
| Watchdog did not fire | `systemctl status dr-watchdog`; `AUTO_FAILOVER=true`; `PRIMARY_HOST` correct |
| App images not pulling on DR | `docker login ghcr.io` with a `read:packages` token |
| Disk growing on primary | replication slot retaining WAL while standby is down (`max_slot_wal_keep_size=2GB` caps it) |

## 5. Cleanup (stop AWS charges after recording)

```bash
cd terraform && terraform destroy
```
