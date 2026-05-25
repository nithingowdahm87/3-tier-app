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
  description = "AWS Account ID (required for VPC peering)"
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
  description = "CIDR block allowed to SSH into the bastion host. MUST be set explicitly - do not use 0.0.0.0/0"
  type        = string
}

variable "key_name" {
  description = "Name of the EC2 key pair for SSH access"
  type        = string
}

variable "bastion_instance_type" {
  description = "EC2 instance type for the bastion host"
  type        = string
  default     = "t3.micro"
}

variable "primary_acm_certificate_arn" {
  description = "ARN of the ACM certificate for HTTPS on the external ALB (primary region)"
  type        = string
}

variable "alb_logs_bucket" {
  description = "S3 bucket name for ALB access logs. Must have the ALB service account bucket policy applied before use."
  type        = string
}

# Web ASG
variable "web_instance_type" {
  description = "Primary instance type for the web tier ASG"
  type        = string
  default     = "t3.small"
}

variable "web_fallback_instance_type" {
  description = "Fallback (spot) instance type for the web tier ASG"
  type        = string
  default     = "t3.medium"
}

variable "web_min_size" { type = number; default = 1 }
variable "web_max_size" { type = number; default = 4 }
variable "web_desired_capacity" { type = number; default = 2 }

variable "web_user_data" {
  description = "User data script for web tier EC2 instances"
  type        = string
  default     = "#!/bin/bash\napt-get update -y\n"
}

# App ASG
variable "app_instance_type" {
  description = "Primary instance type for the app tier ASG"
  type        = string
  default     = "t3.small"
}

variable "app_fallback_instance_type" {
  description = "Fallback (spot) instance type for the app tier ASG"
  type        = string
  default     = "t3.medium"
}

variable "app_min_size" { type = number; default = 1 }
variable "app_max_size" { type = number; default = 4 }
variable "app_desired_capacity" { type = number; default = 2 }

variable "app_user_data" {
  description = "User data script for app tier EC2 instances"
  type        = string
  default     = "#!/bin/bash\napt-get update -y\n"
}

variable "on_demand_base_capacity" {
  description = "Minimum on-demand instances in ASG mixed policy"
  type        = number
  default     = 1
}

# Database
variable "db_name" {
  description = "Aurora database name"
  type        = string
  default     = "appdb"
}

variable "db_username" {
  description = "Aurora master username"
  type        = string
  default     = "admin"
}

variable "db_secret_name" {
  description = "AWS Secrets Manager secret name/ARN containing the Aurora master password. Secret value must be JSON with key 'password'."
  type        = string
}
