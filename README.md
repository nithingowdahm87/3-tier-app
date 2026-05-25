# 3-Tier AWS Infrastructure — MAANG-Level Production (Terraform)

A fully automated, multi-region, production-grade 3-tier application infrastructure on AWS managed entirely with Terraform. **Zero manual prerequisites** — DNS certificates, SSH keys, secrets, monitoring, WAF, and security services are all provisioned by IaC.

## Architecture Overview

```
 Internet
     │
     ▼
[Global Accelerator] — Anycast static IPs, TCP:443, primary/secondary failover
     │
     ▼
[Route53] — Failover routing with health checks (primary NLB → secondary NLB)
     │
[CloudFront] — Static assets CDN (S3 + OAC, TLSv1.2_2021, WAF attached)
     │
     ▼
[NLB] TCP:80 + TCP:443 — public, cross-zone, deletion protection
     │
     ▼
[WAF v2] — OWASP CRS + SQLi + KnownBadInputs managed rules + rate limiting
     │
     ▼
[External ALB] — HTTPS:443 (ACM TLS 1.3) / HTTP:80→301 redirect, access logs
     │
     ▼
[Web ASG] — private subnets, Ubuntu 24.04, IMDSv2, EBS encrypted, Spot/On-Demand
     │
     ▼
[Internal ALB] — port 8080
     │
     ▼
[App ASG] — SSM agent, CloudWatch agent, Secrets Manager + X-Ray instrumentation
     │
     ├──▶ [ElastiCache Redis 7] — Multi-AZ, in-transit+at-rest encryption, auth token
     │
     ▼
[Aurora Global Serverless v2] — read replica autoscaling, IAM DB auth, enhanced monitoring
[DynamoDB Global Table]       — sessions, TTL, PITR, SSE, deletion protection
```

**Regions:** Primary (`us-east-1`) + Secondary DR (`us-west-2`)  
**Connectivity:** VPC Peering (all AZ route tables) + VPC Endpoints (S3, DynamoDB, Secrets Manager, SSM, KMS, X-Ray, CloudWatch, ECR)

## Module Map

| Module | What it provisions |
|---|---|
| `network` | VPC, 3-tier subnets (public/private/db), HA NAT Gateways, route tables, VPC Flow Logs |
| `security` | Least-privilege SGs for ALB, web, internal ALB, app, Aurora, bastion, Redis |
| `vpc_endpoints` | S3 + DynamoDB Gateway endpoints; Secrets Manager, SSM, KMS, CloudWatch, X-Ray, ECR Interface endpoints |
| `logging` | ALB access logs S3 bucket with ELB service account policy |
| `alb` | External ALB (HTTPS + HTTP→HTTPS redirect) + Internal ALB, access logs |
| `nlb` | NLB (TCP:80 + TCP:443), deletion protection, cross-zone LB |
| `dns_cert` | ACM cert (DNS validation) + Route53 health check + failover routing (PRIMARY/SECONDARY) |
| `keypair` | RSA key pair + EC2 registration + private key in Secrets Manager |
| `secrets` | Secrets Manager resource with optional automatic rotation scaffold |
| `compute` | Launch Template (IMDSv2, EBS encrypted) + ASG (Spot/On-Demand mixed) + Secrets Manager IAM |
| `bastion` | HA Bastion ASG across all public subnets |
| `aurora_global` | Aurora MySQL Serverless v2 Global Cluster, IAM DB auth, read replica autoscaling (1–5), enhanced monitoring |
| `elasticache` | Redis 7 replication group, Multi-AZ, TLS, auth token in Secrets Manager, slow-log |
| `dynamodb_global` | DynamoDB Global Table, TTL, PITR, SSE, deletion protection |
| `backup` | AWS Backup daily (7d) + weekly (30d), KMS-encrypted vault |
| `peering` | Cross-region VPC Peering, routes on ALL AZ route tables |
| `waf` | WAF v2 (OWASP + SQLi + BadInputs + rate limit) + Shield Advanced on ALB + NLB |
| `cloudtrail` | Multi-region CloudTrail, log file validation, KMS-encrypted S3 + CloudWatch Logs |
| `guardduty` | GuardDuty both regions, EBS malware scan, EventBridge→SNS for HIGH/CRITICAL findings |
| `security_hub` | Security Hub + FSBP + CIS Benchmark standards, EventBridge→SNS for CRITICAL findings |
| `config_rules` | AWS Config recorder + 9 managed compliance rules |
| `alerting` | SNS topic (KMS), ALB 5xx/p99/healthy-host alarms, Aurora replica lag/connections, DynamoDB throttles, ASG notifications |
| `observability` | CloudWatch Dashboard (8 widgets), X-Ray sampling, Kinesis Firehose→S3, Athena workgroup |
| `cdn` | CloudFront + S3 static assets via OAC, TLSv1.2_2021, WAF, access logs |
| `globalaccelerator` | Global Accelerator, primary+secondary endpoint groups, flow logs |
| `fis` | FIS chaos experiments: EC2 termination (ASG self-healing) + Aurora failover drill |
| `bootstrap-state` | S3 (KMS, versioned, HTTPS-only policy) + DynamoDB for Terraform remote state |

## Prerequisites

- Terraform >= 1.5.0
- AWS CLI configured with appropriate permissions
- A domain registered and hosted in **Route53**

**That's it.** Everything else is created by Terraform.

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
# Fill in bucket and dynamodb_table from step 1 outputs
```

### 3. Set Variables

```bash
cp terraform.tfvars.example terraform.tfvars
# Required: aws_account_id, domain_name, hosted_zone_id, bastion_allowed_cidr
# Required: cloudtrail_bucket_name, config_bucket_name, logs_bucket_name, static_assets_bucket_name
# Required: redis_auth_token (generate: openssl rand -base64 32)
# Optional: alert_email, cloudfront_acm_certificate_arn
```

### 4. First Apply (three-phase for dependency ordering)

```bash
terraform init -backend-config=backend.hcl

# Phase 1: provision cert + secret before everything that depends on them
terraform apply -target=module.dns_cert -target=module.aurora_secret

# Seed the Aurora password
aws secretsmanager put-secret-value \
  --secret-id /prod/aurora/master_password \
  --secret-string '{"password": "YourStrongPassword123!"}'

# Phase 2: full apply
terraform apply
```

### 5. Retrieve SSH Key

```bash
aws secretsmanager get-secret-value \
  --secret-id /prod/keypair/myapp-prod-key \
  --query SecretString --output text > myapp-prod-key.pem
chmod 600 myapp-prod-key.pem
```

## Operational Runbooks

### Run FIS Chaos Experiment (EC2 Termination)

```bash
# Get experiment template ID from Terraform output
template_id=$(terraform output -raw fis_terminate_web_template)

aws fis start-experiment --experiment-template-id $template_id
# Watch CloudWatch Dashboard — ASG should replace the instance within ~3 min
```

### Run Aurora Failover Drill

```bash
template_id=$(terraform output -raw fis_aurora_failover_template)
aws fis start-experiment --experiment-template-id $template_id
# Monitor: aws rds describe-global-clusters --global-cluster-identifier myapp-prod-global-aurora
```

### Query Centralised Logs via Athena

```bash
# Open AWS Console → Athena → select workgroup from Terraform output
terraform output logs_athena_workgroup
# Run SQL against s3://logs_bucket_name/logs/year=.../month=.../day=.../
```

### Trigger Manual CloudWatch Alarm Test

```bash
aws cloudwatch set-alarm-state \
  --alarm-name "myapp-prod-alb-5xx-rate" \
  --state-value ALARM \
  --state-reason "Manual test"
```

## Security Highlights

- **WAF v2** OWASP CRS + SQLi + KnownBadInputs rules on all public ALBs
- **Shield Advanced** protecting ALB and NLB against DDoS
- **GuardDuty** enabled both regions with EBS malware scanning and HIGH/CRITICAL→SNS alerting
- **Security Hub** with FSBP + CIS Benchmark standards continuously evaluating compliance
- **AWS Config** recording all resource changes with 9 compliance rules
- **CloudTrail** multi-region, log file validation, KMS-encrypted
- **VPC Endpoints** — Secrets Manager, SSM, KMS, CloudWatch, ECR, X-Ray traffic never leaves AWS backbone
- **IAM DB Authentication** enabled on Aurora — applications can authenticate using IAM roles
- **Aurora SG egress** locked to VPC CIDR only — no internet egress from database tier
- **Backup vault KMS-encrypted** with CMK and key rotation
- **HTTPS-only policy** on all S3 buckets storing state, logs, and audit data
- **IMDSv2** enforced on all EC2 instances
- **IAM account password policy** — 14+ chars, 90-day expiry, 24 password history
- **Redis** in-transit + at-rest encryption, auth token in Secrets Manager

## Cost Optimisation Notes

- NAT Gateways: 2× per region — largest recurring cost (~$65/mo each)
- Aurora Serverless v2: 0.5–4 ACUs — scales to near-zero in off-hours
- ElastiCache `cache.t4g.small`: Graviton2, ~$25/mo per node
- ASG Spot instances: ~70% savings with `capacity-optimized` strategy
- Global Accelerator: $0.025/hr + data transfer (~$18/mo base)
- Shield Advanced: $3,000/mo — only enable for production workloads under active threat
- Dev/staging: set `az_count = 1`, `redis_num_nodes = 1` to halve NAT + cache costs

## Architecture Diagram

The draw.io diagram: [`docs/draw.io-3tier.txt`](docs/draw.io-3tier.txt)  
Open at [app.diagrams.net](https://app.diagrams.net/) → File → Open from → This Device.
