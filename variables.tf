variable "project_name" {
  description = "Project name used as a prefix for all resources"
  type        = string
  default     = "myapp"
}

variable "environment" {
  description = "Deployment environment (e.g. prod, staging)"
  type        = string
  default     = "prod"

  validation {
    condition     = contains(["prod", "staging", "dev"], var.environment)
    error_message = "environment must be one of: prod, staging, dev."
  }
}

variable "primary_region" {
  description = "AWS primary region"
  type        = string
  default     = "us-east-1"
}

variable "secondary_region" {
  description = "AWS secondary region for DR/global replication"
  type        = string
  default     = "us-west-2"
}

variable "aws_account_id" {
  description = "AWS Account ID"
  type        = string

  validation {
    condition     = can(regex("^[0-9]{12}$", var.aws_account_id))
    error_message = "aws_account_id must be a 12-digit number."
  }
}

variable "owner_tag" {
  description = "Owner tag value applied to all resources (e.g. team name or email). Required by compliance module."
  type        = string
  default     = "platform-team"
}

variable "cost_center_tag" {
  description = "CostCenter tag value applied to all resources. Required by compliance module REQUIRED_TAGS Config rule."
  type        = string
  default     = "engineering"
}

variable "primary_vpc_cidr" {
  description = "CIDR block for the primary VPC"
  type        = string
  default     = "10.0.0.0/16"

  validation {
    condition     = can(cidrhost(var.primary_vpc_cidr, 0))
    error_message = "primary_vpc_cidr must be a valid CIDR block."
  }
}

variable "secondary_vpc_cidr" {
  description = "CIDR block for the secondary VPC"
  type        = string
  default     = "10.1.0.0/16"

  validation {
    condition     = can(cidrhost(var.secondary_vpc_cidr, 0))
    error_message = "secondary_vpc_cidr must be a valid CIDR block."
  }
}

variable "az_count" {
  description = "Number of availability zones to use (min 3 for production-grade HA)"
  type        = number
  default     = 3

  validation {
    condition     = var.az_count >= 2 && var.az_count <= 6
    error_message = "az_count must be between 2 and 6. Use 3 for production."
  }
}

# --- Bastion (legacy - prefer SSM Session Manager for zero-attack-surface access) ---
variable "bastion_enabled" {
  description = "Set to false to disable bastion and use SSM Session Manager instead (recommended for prod)"
  type        = bool
  default     = false
}

variable "bastion_allowed_cidr" {
  description = "CIDR allowed to SSH to bastion. MUST be set explicitly - never use 0.0.0.0/0. Ignored when bastion_enabled = false."
  type        = string
  default     = "10.0.0.0/32"

  validation {
    condition     = var.bastion_allowed_cidr != "0.0.0.0/0"
    error_message = "bastion_allowed_cidr must never be 0.0.0.0/0. Use your office/VPN CIDR."
  }
}

variable "bastion_instance_type" {
  description = "EC2 instance type for the bastion host"
  type        = string
  default     = "t3.micro"
}

variable "domain_name" {
  description = "Primary domain name (e.g. app.example.com). Must exist in the Route53 hosted zone."
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9\\-\\.]+\\.[a-z]{2,}$", var.domain_name))
    error_message = "domain_name must be a valid fully-qualified domain name."
  }
}

variable "hosted_zone_id" {
  description = "Route53 hosted zone ID"
  type        = string
}

variable "cloudfront_acm_certificate_arn" {
  description = "ACM certificate ARN in us-east-1 for CloudFront. Must be created and validated before apply."
  type        = string

  validation {
    condition     = can(regex("^arn:aws:acm:us-east-1:[0-9]{12}:certificate/.+", var.cloudfront_acm_certificate_arn))
    error_message = "cloudfront_acm_certificate_arn must be a valid ACM cert ARN in us-east-1."
  }
}

# Web ASG
variable "web_instance_type" {
  type        = string
  default     = "t3.small"
  description = "Primary instance type for web tier ASG"
}
variable "web_fallback_instance_type" {
  type        = string
  default     = "t3.medium"
  description = "Spot fallback instance type for web tier ASG"
}
variable "web_min_size" {
  type        = number
  default     = 2
  description = "Minimum instances in web ASG (>=2 for HA)"
}
variable "web_max_size" {
  type        = number
  default     = 10
  description = "Maximum instances in web ASG"
}
variable "web_desired_capacity" {
  type        = number
  default     = 3
  description = "Desired instances in web ASG"
}
variable "web_user_data" {
  type        = string
  default     = "#!/bin/bash\nset -euo pipefail\napt-get update -y\napt-get install -y amazon-ssm-agent awscli\nsystemctl enable amazon-ssm-agent\nsystemctl start amazon-ssm-agent\n"
  description = "User data script for web tier. Installs SSM agent by default."
}

# App ASG
variable "app_instance_type" {
  type        = string
  default     = "t3.small"
  description = "Primary instance type for app tier ASG"
}
variable "app_fallback_instance_type" {
  type        = string
  default     = "t3.medium"
  description = "Spot fallback instance type for app tier ASG"
}
variable "app_min_size" {
  type        = number
  default     = 2
  description = "Minimum instances in app ASG (>=2 for HA)"
}
variable "app_max_size" {
  type        = number
  default     = 10
  description = "Maximum instances in app ASG"
}
variable "app_desired_capacity" {
  type        = number
  default     = 3
  description = "Desired instances in app ASG"
}
variable "app_user_data" {
  type        = string
  default     = "#!/bin/bash\nset -euo pipefail\napt-get update -y\napt-get install -y amazon-ssm-agent awscli\nsystemctl enable amazon-ssm-agent\nsystemctl start amazon-ssm-agent\n"
  description = "User data script for app tier. Installs SSM agent by default."
}

variable "on_demand_base_capacity" {
  description = "Minimum on-demand instances in ASG mixed policy"
  type        = number
  default     = 1
}

# Database
variable "db_name" {
  type        = string
  default     = "appdb"
  description = "Aurora database name"
}
variable "db_username" {
  type        = string
  default     = "admin"
  description = "Aurora master username"
}

# ElastiCache Redis
variable "redis_node_type" {
  description = "ElastiCache node type"
  type        = string
  default     = "cache.r7g.large"
}

variable "redis_num_nodes" {
  description = "Number of Redis cache nodes (>=2 enables Multi-AZ, >=3 recommended for prod)"
  type        = number
  default     = 3

  validation {
    condition     = var.redis_num_nodes >= 2
    error_message = "redis_num_nodes must be >= 2 to enable Multi-AZ."
  }
}

# Alerting
variable "alert_email" {
  description = "Email address to receive CloudWatch alarm and ops SNS notifications"
  type        = string

  validation {
    condition     = can(regex("^[^@]+@[^@]+\\.[^@]+$", var.alert_email))
    error_message = "alert_email must be a valid email address."
  }
}

variable "alb_5xx_threshold" {
  description = "Number of ALB 5xx errors in 5 minutes before alarm fires"
  type        = number
  default     = 10
}

variable "aurora_max_connections_threshold" {
  description = "Aurora connection count alarm threshold"
  type        = number
  default     = 800
}

# S3 Bucket names
variable "cloudtrail_bucket_name" {
  description = "Globally unique S3 bucket name for CloudTrail logs"
  type        = string
}

variable "config_bucket_name" {
  description = "Globally unique S3 bucket name for AWS Config snapshots"
  type        = string
}

variable "logs_bucket_name" {
  description = "Globally unique S3 bucket name for centralised logs (Firehose, Athena, Global Accelerator)"
  type        = string
}

variable "static_assets_bucket_name" {
  description = "Globally unique S3 bucket name for CloudFront static assets"
  type        = string
}

# ─── alarms_platform module inputs ───────────────────────────────────────────

variable "route53_health_check_id" {
  description = "Route53 health check ID to monitor. Leave empty to skip the health-check alarm."
  type        = string
  default     = ""
}

variable "secrets_rotation_lambda_name" {
  description = "Name of the Secrets Manager rotation Lambda function. Leave empty to skip the rotation-error alarm."
  type        = string
  default     = ""
}

variable "nat_connection_threshold" {
  description = "NAT Gateway active connection count alarm threshold"
  type        = number
  default     = 50000
}

variable "nat_packet_drop_threshold" {
  description = "NAT Gateway packet drop count alarm threshold (5-minute sum)"
  type        = number
  default     = 100
}

variable "kms_throttle_threshold" {
  description = "KMS throttled requests alarm threshold (5-minute sum)"
  type        = number
  default     = 5
}

variable "secretsmanager_throttle_threshold" {
  description = "Secrets Manager throttled requests alarm threshold (5-minute sum)"
  type        = number
  default     = 5
}

variable "acm_expiry_days_threshold" {
  description = "ACM certificate days-to-expiry alarm threshold (alarm fires when cert expires in fewer than N days)"
  type        = number
  default     = 30
}
