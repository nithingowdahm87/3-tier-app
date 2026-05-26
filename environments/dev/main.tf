# ─── DEV Environment ──────────────────────────────────────────────
# Fully isolated state (separate S3 prefix), separate tfvars, low-cost sizing.
# Deploy: terraform init -backend-config=backend.hcl && terraform apply -var-file=terraform.tfvars

terraform {
  required_version = ">= 1.10.0"   # 1.10+ required for S3 native locking (use_lockfile=true)
  required_providers {
    aws = { source = "hashicorp/aws", version = "~> 5.0" }
    tls = { source = "hashicorp/tls", version = "~> 4.0" }
  }
  # Backend key is injected via -backend-config (backend.hcl locally, ci-backend.hcl in CI)
  # Do NOT hardcode key here — it is set to dev/terraform.tfstate at init time
  backend "s3" {}
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

# Re-use the same root module — state is isolated via backend key above.
module "app" {
  source = "../../"

  providers = {
    aws.primary   = aws.primary
    aws.secondary = aws.secondary
    aws.us_east_1 = aws.us_east_1
  }

  # Override dev-specific sizing (cheap)
  environment              = "dev"
  az_count                 = 1          # single AZ cuts NAT cost by half
  web_min_size             = 1
  web_max_size             = 2
  web_desired_capacity     = 1
  app_min_size             = 1
  app_max_size             = 2
  app_desired_capacity     = 1
  redis_num_nodes          = 1          # no Multi-AZ in dev
  redis_node_type          = "cache.t4g.micro"
  bastion_instance_type    = "t3.micro"
  web_instance_type        = "t3.micro"
  app_instance_type        = "t3.micro"

  # Pass through from tfvars
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
  db_name                         = var.db_name
  db_username                     = var.db_username
}
