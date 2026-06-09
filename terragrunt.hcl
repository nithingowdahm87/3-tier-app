# ─── Root terragrunt.hcl ─────────────────────────────────────────────────────
# Terragrunt v1.x
#
# FIRST TIME SETUP — create the S3 bucket:
#   terragrunt init --backend-bootstrap
#
# All subsequent runs (bucket already exists):
#   terragrunt init
#   terragrunt plan
#   terragrunt apply
#
# NOTE: --backend-bootstrap is a Terragrunt CLI flag — do NOT put it in
# extra_arguments (that forwards it to terraform init which rejects it).

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

    # Native S3 lockfile (AWS provider >= v5) — no DynamoDB table needed
    use_lockfile = true

    # Tags Terragrunt applies when bootstrapping the bucket
    s3_bucket_tags = {
      Project     = local.project
      Environment = local.environment
      ManagedBy   = "terragrunt"
    }

    # Bucket hardening — consumed by Terragrunt bootstrap only,
    # never written into backend_generated.tf
    skip_bucket_versioning             = false  # versioning ON
    skip_bucket_ssencryption           = false  # SSE-S3 ON
    skip_bucket_root_access            = true   # deny root access
    skip_bucket_enforced_tls           = false  # enforce TLS policy
    skip_bucket_public_access_blocking = false  # block public access
  }
}

# ─── Terraform binary settings ───────────────────────────────────────────────
terraform {
  # Auto-pass tfvars on plan/apply/destroy/import/etc.
  extra_arguments "common_vars" {
    commands = get_terraform_commands_that_need_vars()
    optional_var_files = [
      "${get_terragrunt_dir()}/terraform.tfvars",
      "${get_terragrunt_dir()}/environments/${local.environment}.tfvars",
    ]
  }
}
