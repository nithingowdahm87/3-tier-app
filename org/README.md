# AWS Organisation Guardrails

This directory contains **Service Control Policies (SCPs)** for AWS Organisations.

These are **not** deployed by Terraform automatically (they require AWS Organisations master account access). Apply them manually or via a separate `org/main.tf` using the `aws_organizations_policy` resource.

## How to apply

```bash
cd org
terraform init && terraform apply
```

Or attach SCPs manually in the AWS Console → AWS Organizations → Policies → Service Control Policies.

## Policies included

| File | What it prevents |
|---|---|
| `scp_security_services.json` | Disabling CloudTrail, GuardDuty, Config, Security Hub |
| `scp_s3_public_access.json` | Removing S3 Block Public Access at account level |
| `scp_region_restriction.json` | Deploying resources outside approved regions |
| `scp_protect_state.json` | Deleting / modifying the Terraform remote state bucket or DynamoDB lock table |
