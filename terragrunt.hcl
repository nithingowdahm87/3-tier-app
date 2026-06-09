# ─── Root terragrunt.hcl ─────────────────────────────────────────────────────
# Terragrunt auto-creates the S3 bucket + DynamoDB lock table on first run.
# No manual AWS CLI steps needed.

locals {
  # Read from terraform.tfvars.example or override via env vars
  project     = "nithin-3tier"
  environment = get_env("TF_VAR_environment", "prod")
  region      = get_env("TF_VAR_primary_region", "ap-south-1")

  bucket_name    = "${local.project}-${local.environment}-tfstate"
  lock_table     = "${local.project}-${local.environment}-tfstate-lock"
  state_key      = "3-tier-app/terraform.tfstate"
}

# ─── Remote State (auto-created by Terragrunt) ───────────────────────────────
remote_state {
  backend = "s3"

  # Terragrunt will create the bucket + DynamoDB table automatically
  # if they do not exist when you run `terragrunt init`
  generate = {
    path      = "backend_generated.tf"
    if_exists = "overwrite_terragrunt"
  }

  config = {
    bucket         = local.bucket_name
    key            = local.state_key
    region         = local.region
    encrypt        = true
    dynamodb_table = local.lock_table

    # Security hardening on the auto-created bucket
    s3_bucket_tags = {
      Project     = local.project
      Environment = local.environment
      ManagedBy   = "terragrunt"
    }

    dynamodb_table_tags = {
      Project     = local.project
      Environment = local.environment
      ManagedBy   = "terragrunt"
    }

    # Enable bucket versioning so state history is preserved
    enable_bucket_versioning = true

    # Block all public access on the state bucket
    enable_server_side_encryption = true
    skip_bucket_root_access       = true
    skip_bucket_enforced_tls      = false
  }
}

# ─── Terraform binary settings ───────────────────────────────────────────────
terraform {
  # Automatically run terraform init before plan/apply
  extra_arguments "common_vars" {
    commands = get_terraform_commands_that_need_vars()
    optional_var_files = [
      "${get_terragrunt_dir()}/terraform.tfvars",
      "${get_terragrunt_dir()}/environments/${local.environment}.tfvars",
    ]
  }
}

# ─── Generate providers.tf (overrides the static backend block) ──────────────
# This is NOT needed if you keep providers.tf with backend "s3" {} unchanged.
# Terragrunt injects backend_generated.tf which takes precedence.
