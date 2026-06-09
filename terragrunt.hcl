# ─── Root terragrunt.hcl ─────────────────────────────────────────────────────
# Terragrunt auto-creates the S3 bucket + DynamoDB lock table on first run.
# No manual AWS CLI steps needed.

locals {
  project     = "nithin-3tier"
  environment = get_env("TF_VAR_environment", "prod")
  region      = get_env("TF_VAR_primary_region", "ap-south-1")

  bucket_name = "${local.project}-${local.environment}-tfstate"
  lock_table  = "${local.project}-${local.environment}-tfstate-lock"
  state_key   = "3-tier-app/terraform.tfstate"
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

    # Tags applied by Terragrunt when it creates the bucket/table
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

    # These are Terragrunt bucket-creation controls (NOT S3 backend args).
    # They tell Terragrunt how to configure the bucket it creates —
    # they are NOT forwarded into the generated backend block.
    skip_bucket_versioning      = false   # false  → versioning ON
    skip_bucket_ssencryption    = false   # false  → SSE-S3 encryption ON
    skip_bucket_root_access     = true    # true   → deny root account access
    skip_bucket_enforced_tls    = false   # false  → enforce TLS on bucket policy
    skip_bucket_public_access_blocking = false # false → block all public access
  }
}

# ─── Terraform binary settings ───────────────────────────────────────────────
terraform {
  extra_arguments "common_vars" {
    commands = get_terraform_commands_that_need_vars()
    optional_var_files = [
      "${get_terragrunt_dir()}/terraform.tfvars",
      "${get_terragrunt_dir()}/environments/${local.environment}.tfvars",
    ]
  }
}
