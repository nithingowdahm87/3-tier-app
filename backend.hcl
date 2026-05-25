# Partial backend configuration — fill in your real values and run:
#   terraform init -backend-config=backend.hcl
#
# NEVER commit this file with real values to version control.
# Add backend.hcl to .gitignore if it contains real bucket/table names.

bucket         = "REPLACE_WITH_YOUR_STATE_BUCKET"
region         = "us-east-1"
dynamodb_table = "REPLACE_WITH_YOUR_LOCK_TABLE"
