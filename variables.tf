variable "project_name" {
  description = "Project name used as a prefix for all resources"
  type        = string
  default     = "myapp"
}

variable "environment" {
  description = "Deployment environment (e.g. prod, staging)"
  type        = string
  default     = "prod"
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
}

variable "primary_vpc_cidr" {
  description = "CIDR block for the primary VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "secondary_vpc_cidr" {
  description = "CIDR block for the secondary VPC"
  type        = string
  default     = "10.1.0.0/16"
}

variable "az_count" {
  description = "Number of availability zones to use"
  type        = number
  default     = 2
}

variable "bastion_allowed_cidr" {
  description = "CIDR allowed to SSH to bastion. MUST be set explicitly — never use 0.0.0.0/0"
  type        = string
}

variable "bastion_instance_type" {
  description = "EC2 instance type for the bastion host"
  type        = string
  default     = "t3.micro"
}

# DNS
variable "domain_name" {
  description = "Primary domain name (e.g. app.example.com). Must exist in the Route53 hosted zone."
  type        = string
}

variable "hosted_zone_id" {
  description = "Route53 hosted zone ID"
  type        = string
}

# Web ASG
variable "web_instance_type"         { type = string; default = "t3.small" }
variable "web_fallback_instance_type" { type = string; default = "t3.medium" }
variable "web_min_size"               { type = number; default = 1 }
variable "web_max_size"               { type = number; default = 4 }
variable "web_desired_capacity"       { type = number; default = 2 }
variable "web_user_data"              { type = string; default = "#!/bin/bash\napt-get update -y\n" }

# App ASG
variable "app_instance_type"         { type = string; default = "t3.small" }
variable "app_fallback_instance_type" { type = string; default = "t3.medium" }
variable "app_min_size"               { type = number; default = 1 }
variable "app_max_size"               { type = number; default = 4 }
variable "app_desired_capacity"       { type = number; default = 2 }
variable "app_user_data"              { type = string; default = "#!/bin/bash\napt-get update -y\n" }

variable "on_demand_base_capacity" {
  description = "Minimum on-demand instances in ASG mixed policy"
  type        = number
  default     = 1
}

# Database
variable "db_name"     { type = string; default = "appdb" }
variable "db_username" { type = string; default = "admin" }
variable "db_secret_name" {
  description = "Secrets Manager secret name for Aurora password — auto-derived from environment"
  type        = string
  default     = ""
}

# ElastiCache Redis
variable "redis_node_type" {
  description = "ElastiCache node type"
  type        = string
  default     = "cache.t4g.small"
}

variable "redis_num_nodes" {
  description = "Number of Redis cache nodes (>=2 enables Multi-AZ)"
  type        = number
  default     = 2
}

variable "redis_auth_token" {
  description = "Redis AUTH token — generate with: openssl rand -base64 32"
  type        = string
  sensitive   = true
}

# Alerting
variable "alert_email" {
  description = "Email address to receive CloudWatch alarm and ops SNS notifications"
  type        = string
  default     = ""
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

# S3 Bucket names (must be globally unique)
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

# CloudFront ACM certificate (must be in us-east-1)
variable "cloudfront_acm_certificate_arn" {
  description = "ACM certificate ARN in us-east-1 for CloudFront (static.domain_name). Create manually or via bootstrap if your primary region is not us-east-1."
  type        = string
  default     = ""
}
