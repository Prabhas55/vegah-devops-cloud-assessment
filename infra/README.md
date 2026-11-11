# VEGAH Infrastructure and Disaster Recovery

This directory contains the infrastructure templates, automation
scripts, operational procedures, and disaster recovery documentation
for the VEGAH multi-region deployment.

## Regional Architecture

| Region | Role | AWS Region |
|---|---|---|
| Mumbai | Primary | ap-south-1 |
| Singapore | Secondary DR | ap-southeast-1 |

Mumbai handles normal production traffic. Singapore provides the
secondary disaster recovery environment.

## Documentation

| File | Description |
|---|---|
| ARCHITECTURE.md | Multi-region architecture and traffic flow |
| DR-IMPLEMENTATION.md | Disaster recovery implementation |
| DR-TEST-REPORT.md | Controlled failover and failback test results |
| FAILBACK-RUNBOOK.md | Singapore-to-Mumbai recovery procedure |
| DATA-RESILIENCE.md | PostgreSQL replication, Redis and backup considerations |
| OPERATIONS-RUNBOOK.md | Operational health checks and troubleshooting |

## Infrastructure as Code

The `terraform/` directory contains Terraform templates for the
Singapore DR infrastructure.

Review `terraform/README.md` and `terraform.tfvars.example`
before using the configuration.

Do not apply the templates against existing infrastructure without
reviewing the Terraform plan.

## Configuration Management

The `ansible/` directory contains:

- `ansible.cfg` - Ansible configuration
- `inventory.ini.example` - Example inventory
- `requirements.yml` - Ansible collection requirements
- `site.yml` - Configuration management playbook

## Automation Scripts

The `scripts/` directory contains:

- `failover.sh` - Failover procedure template
- `failback.sh` - Failback procedure template

Review scripts before execution. The repository templates are
not a replacement for the tested live recovery procedure.

## Important Operational Notes

- Mumbai is the primary region.
- Singapore is the secondary disaster recovery region.
- PostgreSQL replication is asynchronous.
- Redis does not have continuous cross-region synchronization.
- DNS failover is configured separately through Route 53.
- Failover and failback require controlled database role changes.
- Always verify application and worker job processing after recovery.

## Safety

These files document the implementation and provide reusable
templates. Review all configurations, permissions, costs, and
execution plans before making changes to AWS resources.
