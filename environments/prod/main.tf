# ─── PROD Environment ─────────────────────────────────────────────────────────
# Full production sizing. Multi-AZ, HA Redis, full autoscaling.

terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = { source = "hashicorp/aws", version = "~> 5.0" }
    tls = { source = "hashicorp/tls", version = "~> 4.0" }
  }
  backend "s3" {
    key     = "3tier-app/prod/terraform.tfstate"
    encrypt = true
  }
}

provider "aws" {
  alias  = "primary"
  region = var.primary_region
}
provider "aws" {
  alias  = "secondary"
  region = var.secondary_region
}
provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"
}

module "app" {
  source = "../../"

  providers = {
    aws.primary   = aws.primary
    aws.secondary = aws.secondary
    aws.us_east_1 = aws.us_east_1
  }

  # Full prod sizing — override nothing, uses root module defaults
  environment = "prod"

  project_name                    = var.project_name
  primary_region                  = var.primary_region
  secondary_region                = var.secondary_region
  aws_account_id                  = var.aws_account_id
  primary_vpc_cidr                = var.primary_vpc_cidr
  secondary_vpc_cidr              = var.secondary_vpc_cidr
  domain_name                     = var.domain_name
  hosted_zone_id                  = var.hosted_zone_id
  bastion_allowed_cidr            = var.bastion_allowed_cidr
  alert_email                     = var.alert_email
  cloudtrail_bucket_name          = var.cloudtrail_bucket_name
  config_bucket_name              = var.config_bucket_name
  logs_bucket_name                = var.logs_bucket_name
  static_assets_bucket_name       = var.static_assets_bucket_name
  cloudfront_acm_certificate_arn  = var.cloudfront_acm_certificate_arn
  redis_auth_token                = var.redis_auth_token
  alb_5xx_threshold               = var.alb_5xx_threshold
  aurora_max_connections_threshold = var.aurora_max_connections_threshold
  db_name                         = var.db_name
  db_username                     = var.db_username
}
