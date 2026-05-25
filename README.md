# AWS 3-Tier Multi-Region Terraform Infrastructure

Production-grade, modular Terraform for a 3-tier application across **us-east-1** (primary) and **us-west-2** (secondary).

## Architecture Overview

```
Internet
   │
   ▼
[NLB] ──── Layer 4 (TCP/TLS passthrough)
   │
   ▼
[ALB] ──── Layer 7 (HTTP routing, host/path rules)
   │
   ▼
[Web Tier] ──── Nginx on EC2 ASG (public/private via ALB path)
   │
   ▼
[Internal ALB]
   │
   ▼
[App Tier] ──── Spring Boot on EC2 ASG (private subnets)
   │
   ├──▶ [Aurora Global DB] ──── Primary (us-east-1) → Replica (us-west-2)
   └──▶ [DynamoDB Global Table] ──── us-east-1 ↔ us-west-2

[Bastion Host] ──── SSH access to private EC2s
[AWS Backup] ──── Scheduled backups: Aurora + DynamoDB
[Lambda + EventBridge] ──── Backup export to S3
[VPC Peering] ──── Cross-region private connectivity
[Terraform State] ──── S3 + DynamoDB locking
```

## Module Structure

```
.
├── bootstrap-state/
├── modules/
│   ├── network/
│   ├── security/
│   ├── bastion/
│   ├── nlb/
│   ├── alb/
│   ├── compute/
│   ├── aurora_global/
│   ├── dynamodb_global/
│   ├── backup/
│   ├── backup_export/
│   └── peering/
├── environments/
│   └── prod/
└── lambda/
```

## Multi-Region Strategies

- `active-active`: both regions serve traffic.
- `active-passive`: primary active, secondary standby.
- `warm-standby`: secondary runs reduced capacity and scales on failover.

## Notes

- Route 53 and ACM intentionally excluded.
- Uses launch templates for ASG mixed instances policy.
- Uses latest Ubuntu 24.04 LTS lookup.
- Uses t2.micro/t3.micro for current low-cost setup.
