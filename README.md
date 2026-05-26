# 3-Tier Production AWS Architecture

[![Terraform](https://img.shields.io/badge/Terraform-%E2%89%A51.10-623CE4?logo=terraform)](https://www.terraform.io/)
[![AWS](https://img.shields.io/badge/AWS-Multi--Region-FF9900?logo=amazonaws)](https://aws.amazon.com/)
[![CI/CD](https://img.shields.io/badge/CI%2FCD-GitHub%20Actions-2088FF?logo=github-actions)](https://github.com/nithingowdahm87/3-tier-app/actions)

**Production-grade, multi-region, highly available 3-tier web application infrastructure on AWS built with Terraform.**

This repository provisions:
- ✅ Multi-region active-standby (us-east-1 → us-west-2)
- ✅ Auto-scaling compute with mixed on-demand + spot (70-80% cost savings)
- ✅ Aurora Global MySQL + ElastiCache Redis + DynamoDB Global Tables
- ✅ CloudFront CDN + AWS Global Accelerator
- ✅ Full observability (CloudWatch, X-Ray, Athena, Kinesis)
- ✅ DevSecOps pipeline (Checkov, tfsec, Trivy)
- ✅ Keyless OIDC authentication
- ✅ Automated drift detection + module versioning

---

## Architecture Diagram

![Architecture](docs/architecture.png)

> **Upload the architecture diagram:** Save the image you provided as `docs/architecture.png` in this repo.

---

## Quick Start

### Prerequisites
- Terraform ≥ 1.10.0
- AWS Account with Administrator access
- GitHub Account (for CI/CD)

### 1. Bootstrap Terraform State

```bash
cd bootstrap-state
cp terraform.tfvars.example terraform.tfvars
vim terraform.tfvars  # Set state_bucket_name
terraform init && terraform apply
```

### 2. Configure Environment

```bash
cd ../environments/prod
cp backend.hcl.example backend.hcl
cp terraform.tfvars.example terraform.tfvars
vim backend.hcl      # Set bucket name
vim terraform.tfvars # Set required vars
```

### 3. Deploy

```bash
terraform init -backend-config=backend.hcl
terraform plan -var-file=terraform.tfvars
terraform apply
```

**Deployment time:** ~25-30 minutes

---

## Repository Structure

```
3-tier-app/
├── .github/workflows/
│   ├── terraform-pipeline.yml  # Multi-branch CI/CD
│   ├── drift-detection.yml      # Nightly drift check
│   └── module-release.yml       # Auto semver tagging
├── bootstrap-state/         # S3 state bucket + KMS
├── environments/
│   ├── dev/
│   ├── stage/
│   └── prod/
├── modules/                 # Reusable Terraform modules
│   ├── network/             # VPC, subnets
│   ├── compute/             # ASG, launch templates
│   ├── alb/ nlb/            # Load balancers
│   ├── aurora_global/       # Aurora MySQL
│   ├── elasticache/         # Redis
│   ├── dynamodb_global/     # DynamoDB
│   ├── cdn/                 # CloudFront
│   ├── waf/                 # AWS WAF
│   ├── observability/       # Logs, metrics
│   ├── security_hub/        # Security posture
│   └── ... (31 modules total)
├── docs/
│   ├── architecture.png     # Diagram
│   ├── oidc-setup.md        # OIDC guide
│   └── bootstrap.md         # State setup
├── main.tf
├── variables.tf
├── providers.tf
└── README.md
```

---

## CI/CD Workflow

### Branch Strategy

| Branch | Environment | Auto-Deploy | Approval |
|--------|-------------|-------------|----------|
| `feature/*` / `develop` | dev | ❌ Plan only | No |
| `stage` | stage | ✅ Yes | No |
| `main` | prod | ✅ Yes | ✅ Required |

### Terraform Pipeline

1. **Lint**: `terraform fmt`, TFLint
2. **Security**: Checkov, tfsec, Trivy
3. **Validate**: `terraform validate`
4. **Plan**: Per-environment plan
5. **Apply**: Auto (stage) / Manual approval (prod)

### Drift Detection

Runs nightly at 2 AM UTC:
- Runs `terraform plan` against prod
- Opens GitHub Issue if drift detected
- Auto-closes when drift resolved

### Module Versioning

Auto-tags modules on merge to `main`:
- `[major]` in commit → `v2.0.0`
- `[minor]` in commit → `v1.1.0`
- Default → `v1.0.1`

---

## Architecture Components

### Global Layer
- **Route53**: DNS + health checks
- **CloudFront**: CDN with ACM certificate
- **Global Accelerator**: Static anycast IPs
- **IAM**: Password policy enforcement

### Primary Region (us-east-1)
- **VPC**: `10.0.0.0/16` across 3 AZs
- **Web ASG**: t3.small (on-demand) + t3.medium (spot), 2-10 instances
- **App ASG**: t3.small (on-demand) + t3.medium (spot), 2-10 instances
- **ALB + NLB**: HTTPS/TCP load balancing
- **Aurora Global MySQL**: db.r6g.large, writer in us-east-1
- **ElastiCache Redis**: cache.r7g.large, 3-node cluster
- **DynamoDB Global**: Session table

### Secondary Region (us-west-2)
Identical standby infrastructure:
- VPC `10.1.0.0/16`
- Aurora read replica
- VPC peering for replication

### Security & Compliance
- **GuardDuty**: Threat detection
- **Security Hub**: Security posture
- **CloudTrail**: Audit logs (90 days)
- **AWS Config**: Compliance monitoring
- **WAF**: OWASP Top 10 protection
- **Secrets Manager**: DB credentials with auto-rotation

### Observability
- **CloudWatch Logs**: ALB, VPC Flow, Lambda
- **Kinesis Firehose**: Logs → S3 → Athena
- **X-Ray**: Distributed tracing
- **SNS**: Alarm notifications

---

## OIDC Setup

Replace static AWS keys with keyless OIDC. Follow [`docs/oidc-setup.md`](docs/oidc-setup.md):

1. Create GitHub OIDC provider in AWS IAM
2. Create IAM role `github-actions-terraform`
3. Store `AWS_OIDC_ROLE_ARN` in GitHub Secrets

---

## Disaster Recovery

**RPO:** < 5 minutes (Aurora replication lag)  
**RTO:** < 15 minutes (Aurora promotion + Route53 failover)

### Failover Procedure

```bash
# 1. Promote Aurora in us-west-2
aws rds promote-read-replica-db-cluster \
  --db-cluster-identifier myapp-prod-cluster-usw2 \
  --region us-west-2

# 2. Route53 health checks auto-failover ALB
# 3. Verify traffic shift
watch -n 1 "curl -I https://app.example.com"
```

---

## Cost Optimization

**Estimated monthly cost (prod):** ~$1,467/month

| Service | Cost | Notes |
|---------|------|-------|
| EC2 (Web + App) | $90 | Spot = 70-80% savings |
| Aurora Global | $580 | Use Savings Plans for 30-50% off |
| ElastiCache | $520 | r7g graviton instances |
| DynamoDB | $30 | On-demand billing |
| ALB + CloudFront | $125 | |
| Global Accelerator | $60 | |
| CloudWatch + S3 | $62 | Enable S3 Intelligent-Tiering |

---

## Module Versioning

Pin modules to specific versions:

```hcl
# Prod: pin exact version
module "network" {
  source = "git::https://github.com/nithingowdahm87/3-tier-app//modules/network?ref=v1.2.0"
}

# Dev: float to latest minor
module "alb" {
  source = "git::https://github.com/nithingowdahm87/3-tier-app//modules/alb?ref=v1.3"
}
```

---

## Support

- [OIDC Setup Guide](docs/oidc-setup.md)
- [Bootstrap Guide](docs/bootstrap.md)
- [GitHub Issues](https://github.com/nithingowdahm87/3-tier-app/issues)

---

**Built with ❤️ by [@nithingowdahm87](https://github.com/nithingowdahm87)**
