# Partial backend configuration — fill in your real values and run:
#   terraform init -backend-config=backend.hcl
#
# NEVER commit this file with real values to version control.
# Add backend.hcl to .gitignore if it contains real bucket names.
#
# NOTE: Using S3 native locking (use_lockfile = true) — no DynamoDB table needed.
# Requires Terraform >= 1.10 and S3 bucket versioning enabled.

bucket       = "REPLACE_WITH_YOUR_STATE_BUCKET"
region       = "us-east-1"
encrypt      = true
use_lockfile = true
