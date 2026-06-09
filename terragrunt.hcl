# ─── Root terragrunt.hcl ─────────────────────────────────────────────────────
# Terragrunt v1.x: bucket + lock file auto-created via --backend-bootstrap.
# Run: terragrunt init --backend-bootstrap  (first time only)
# Subsequent runs: terragrunt plan / terragrunt apply

locals {
  project     = "nithin-3tier"
  environment = get_env("TF_VAR_environment", "prod")
  region      = get_env("TF_VAR_primary_region", "ap-south-1")

  bucket_name = "${local.project}-${local.environment}-tfstate"
  state_key   = "3-tier-app/terraform.tfstate"
}

# ─── Remote State ────────────────────────────────────────────────────────────
remote_state {
  backend = "s3"

  generate = {
    path      = "backend_generated.tf"
    if_exists = "overwrite_terragrunt"
  }

  config = {
    bucket  = local.bucket_name
    key     = local.state_key
    region  = local.region
    encrypt = true

    # Native S3 lockfile (AWS provider >= 5.x) — replaces deprecated dynamodb_table
    use_lockfile = true

    # Tags applied by Terragrunt when it bootstraps the bucket
    s3_bucket_tags = {
      Project     = local.project
      Environment = local.environment
      ManagedBy   = "terragrunt"
    }

    # Terragrunt bucket-creation controls (never written into backend_generated.tf)
    skip_bucket_versioning             = false  # versioning ON
    skip_bucket_ssencryption           = false  # SSE-S3 encryption ON
    skip_bucket_root_access            = true   # deny root account access
    skip_bucket_enforced_tls           = false  # enforce TLS bucket policy
    skip_bucket_public_access_blocking = false  # block all public access
  }
}

# ─── Terraform binary settings ───────────────────────────────────────────────
terraform {
  # Auto-pass --backend-bootstrap on every init so the bucket is created
  # automatically without needing to remember the flag manually.
  extra_arguments "bootstrap_init" {
    commands  = ["init"]
    arguments = ["--backend-bootstrap"]
  }

  # Auto-pass tfvars files on plan/apply/destroy/etc.
  extra_arguments "common_vars" {
    commands = get_terraform_commands_that_need_vars()
    optional_var_files = [
      "${get_terragrunt_dir()}/terraform.tfvars",
      "${get_terragrunt_dir()}/environments/${local.environment}.tfvars",
    ]
  }
}
