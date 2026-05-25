# 3-Tier AWS Infrastructure (Terraform)

A production-grade, multi-region 3-tier application infrastructure on AWS, fully managed with Terraform.

## Architecture Overview

```
 Internet
    │
    ▼
 [NLB] (public, cross-zone)
    │
    ▼
 [External ALB] (HTTPS:443 with ACM cert, HTTP:80 → 301 redirect)
    │
    ▼
 [Web ASG] (private subnets, Ubuntu 24.04, IMDSv2, EBS encrypted)
    │
    ▼
 [Internal ALB] (port 8080)
    │
    ▼
 [App ASG] (private subnets, SSM + CloudWatch agent)
    │
    ▼
 [Aurora Global Serverless v2] (db subnets, encrypted, PITR, enhanced monitoring)
 [DynamoDB Global Table]        (sessions, PITR, SSE, deletion protection)
```

**Regions:** Primary (`us-east-1`) + Secondary DR (`us-west-2`) connected via VPC Peering

## Module Structure

| Module | Description |
|---|---|
| `network` | VPC, 3-tier subnets, HA NAT Gateways (one per AZ), route tables |
| `security` | Security groups with least-privilege rules for each tier |
| `alb` | External ALB (HTTPS + HTTP→HTTPS redirect) + Internal ALB |
| `nlb` | Network Load Balancer fronting the External ALB |
| `compute` | Launch Template (IMDSv2, encrypted EBS) + ASG with mixed Spot/On-Demand |
| `bastion` | HA Bastion ASG (min=1, spans all public subnets across AZs) |
| `aurora_global` | Aurora MySQL Serverless v2 Global Cluster with enhanced monitoring on both regions |
| `dynamodb_global` | DynamoDB Global Table with PITR, SSE, deletion protection |
| `backup` | AWS Backup with daily (7d) + weekly (30d) retention |
| `peering` | Cross-region VPC Peering with bidirectional routes |
| `bootstrap-state` | S3 + DynamoDB for Terraform remote state (run once first) |

## Prerequisites

- Terraform >= 1.5.0
- AWS CLI configured with appropriate permissions
- An ACM certificate issued in the primary region for your domain
- An EC2 Key Pair created in both regions
- An AWS Secrets Manager secret containing the Aurora master password (see below)

## Quick Start

### 1. Create Aurora Password in Secrets Manager

Before deploying, store the Aurora master password in AWS Secrets Manager:

```bash
aws secretsmanager create-secret \
  --name "/prod/aurora/master_password" \
  --secret-string '{"password": "YourStrongPassword123!"}' \
  --region us-east-1
```

Then set `db_secret_name = "/prod/aurora/master_password"` in your `terraform.tfvars`.

### 2. Bootstrap Remote State (one-time)

```bash
cd bootstrap-state
terraform init
terraform apply
```

Note the output `state_bucket` and `lock_table` values.

### 3. Configure Backend

Copy and fill in `backend.hcl`:

```bash
cp backend.hcl.example backend.hcl
# Edit backend.hcl with your real bucket and table names
```

> ⚠️ `backend.hcl` is gitignored — never commit it with real values.

### 4. Set Variables

```bash
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your real values
```

### 5. Deploy

```bash
terraform init -backend-config=backend.hcl
terraform plan
terraform apply
```

## Security Highlights

- IMDSv2 enforced on all EC2 instances (`http_tokens = required`, hop limit = 1)
- EBS volumes encrypted at rest on all instances
- ALB enforces TLS 1.3 (`ELBSecurityPolicy-TLS13-1-2-2021-06`)
- Aurora storage encrypted + CloudWatch audit/error/slowquery logs
- Aurora master password stored in AWS Secrets Manager — never in tfvars or env vars
- Bastion SSH restricted to explicit CIDR (no `0.0.0.0/0` default)
- Bastion runs as an ASG (min=1) across multiple AZs for high availability
- DynamoDB SSE enabled with deletion protection
- S3 state bucket has versioning, AES256 encryption, and public access blocked
- All sensitive Terraform outputs marked `sensitive = true`

## Architecture Diagram

The draw.io diagram is located at [`docs/draw.io-3tier.txt`](docs/draw.io-3tier.txt).  
Open it at [app.diagrams.net](https://app.diagrams.net/) via File → Open from → This Device.

## Cost Notes

- NAT Gateways: 2x per region (HA) — largest recurring cost
- Aurora Serverless v2: scales from 0.5 to 4 ACUs — pay for what you use
- ASG Spot instances: up to ~70% savings on compute with `capacity-optimized` strategy
- Consider reducing `az_count = 1` and single NAT Gateway for dev/staging environments
