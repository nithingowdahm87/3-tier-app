# 3-Tier AWS Infrastructure (Terraform)

A production-grade, multi-region 3-tier application infrastructure on AWS, fully managed with Terraform. **Zero manual prerequisites** — everything from DNS certificates to SSH keys is provisioned by IaC.

## Architecture Overview

```
 Internet
    │
    ▼
 [Route53 A record] → domain_name
    │
    ▼
 [NLB] TCP:80 + TCP:443 (public, cross-zone)
    │
    ▼
 [External ALB] HTTPS:443 (ACM TLS 1.3) / HTTP:80 → 301 redirect
    │
    ▼
 [Web ASG] private subnets, Ubuntu 24.04, IMDSv2, EBS encrypted
    │
    ▼
 [Internal ALB] port 8080
    │
    ▼
 [App ASG] private subnets, SSM + CloudWatch agent, Secrets Manager access
    │
    ▼
 [Aurora Global Serverless v2]  db subnets (isolated, no NAT), enhanced monitoring
 [DynamoDB Global Table]         sessions, TTL, PITR, SSE
```

**Regions:** Primary (`us-east-1`) + Secondary DR (`us-west-2`) via VPC Peering (all AZ route tables)

## Module Structure

| Module | Description |
|---|---|
| `network` | VPC, 3-tier subnets, HA NAT Gateways, route tables, VPC Flow Logs |
| `security` | Least-privilege security groups for each tier |
| `logging` | ALB access logs S3 bucket with ELB service account policy + lifecycle |
| `alb` | External ALB (HTTPS + HTTP→HTTPS) + Internal ALB, access logs enabled |
| `nlb` | NLB (TCP:80 + TCP:443) fronting the External ALB |
| `dns_cert` | ACM certificate (DNS validation) + Route53 A record → NLB |
| `keypair` | TLS RSA key pair + EC2 registration + private key stored in Secrets Manager |
| `secrets` | Secrets Manager secret resource with optional rotation scaffold |
| `compute` | Launch Template (IMDSv2, EBS encrypted) + ASG (Spot/On-Demand) + Secrets Manager IAM |
| `bastion` | HA Bastion ASG (min=1) across all public subnets |
| `aurora_global` | Aurora MySQL Serverless v2 Global Cluster, enhanced monitoring both regions |
| `dynamodb_global` | DynamoDB Global Table, TTL, PITR, SSE, deletion protection |
| `backup` | AWS Backup daily (7d) + weekly (30d) |
| `peering` | Cross-region VPC Peering, routes on ALL AZ route tables both sides |
| `bootstrap-state` | S3 + DynamoDB for Terraform remote state (one-time) |

## Prerequisites

- Terraform >= 1.5.0
- AWS CLI configured with appropriate permissions
- A domain registered and hosted in **Route53** (provide `hosted_zone_id` + `domain_name`)

**That's it.** Keys, certs, S3 buckets, and secrets are all created by Terraform.

## Deploy

### 1. Bootstrap Remote State (one-time)

```bash
cd bootstrap-state
terraform init && terraform apply
cd ..
```

### 2. Configure Backend

```bash
cp backend.hcl.example backend.hcl
# Fill in bucket and dynamodb_table from step 1 output
```

### 3. Set Variables

```bash
cp terraform.tfvars.example terraform.tfvars
# Fill in: aws_account_id, domain_name, hosted_zone_id, bastion_allowed_cidr
```

### 4. First Apply (two-phase for secret dependency)

```bash
terraform init -backend-config=backend.hcl

# Phase 1: create the secret resource before Aurora tries to read it
terraform apply -target=module.aurora_secret

# Seed the Aurora password (one-time)
aws secretsmanager put-secret-value \
  --secret-id /prod/aurora/master_password \
  --secret-string '{"password": "YourStrongPassword123!"}'

# Phase 2: deploy everything
terraform apply
```

### 5. Get SSH Key

```bash
# Retrieve the private key Terraform stored in Secrets Manager
aws secretsmanager get-secret-value \
  --secret-id /prod/keypair/myapp-prod-key \
  --query SecretString --output text > myapp-prod-key.pem
chmod 600 myapp-prod-key.pem
```

## Security Highlights

- IMDSv2 enforced on all EC2 instances
- EBS volumes encrypted at rest on all instances
- ALB enforces TLS 1.3 (`ELBSecurityPolicy-TLS13-1-2-2021-06`)
- Aurora storage encrypted, CloudWatch audit/error/slowquery logs
- Aurora password in Secrets Manager — never in tfvars, env vars, or state
- EC2 IAM roles scoped to read only secrets under `/${environment}/*`
- Bastion SSH restricted to explicit CIDR; HA ASG across multiple AZs
- DynamoDB SSE, deletion protection, TTL for session cleanup
- VPC Flow Logs on both primary and secondary VPCs (CloudWatch, 30d retention)
- DB subnets fully isolated — no outbound internet/NAT routes
- VPC peering routes on ALL AZ route tables (no silent routing gaps)
- S3 state bucket: versioned, AES256, public access blocked

## Architecture Diagram

The draw.io diagram: [`docs/draw.io-3tier.txt`](docs/draw.io-3tier.txt)  
Open at [app.diagrams.net](https://app.diagrams.net/) → File → Open from → This Device.

## Cost Notes

- NAT Gateways: 2x per region — largest recurring cost
- Aurora Serverless v2: 0.5–4 ACUs — pay for what you use
- ASG Spot instances: ~70% savings with `capacity-optimized`
- Dev/staging: set `az_count = 1` to halve NAT Gateway cost
