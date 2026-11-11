# VEGAH Singapore DR Infrastructure

Terraform configuration for a fresh secondary DR environment
in AWS Singapore (ap-southeast-1).

## Resources

- VPC
- Public subnet
- Internet Gateway
- Route table
- Security group
- IAM role for Systems Manager
- EC2 instance profile
- EC2 DR server
- Encrypted gp3 root EBS volume

## Commands

```bash
terraform init
terraform fmt -recursive
terraform validate
terraform plan
```

Review the plan carefully before deployment.

## Security

- SSH ingress is not configured.
- Systems Manager is used for server administration.
- IMDSv2 is required.
- EBS encryption is enabled.

## Scope

This configuration does not create Mumbai infrastructure,
Route 53 records, health checks, or database replication.

It defines a fresh DR environment. Do not apply it against
an account containing an existing deployment without
reviewing resource duplication and cost implications.
