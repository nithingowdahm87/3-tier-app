# Partial backend configuration for S3 remote state.
# Usage: terraform init -backend-config=backend.hcl
#
# Fill in the values below before running terraform init.

region = "ap-south-1"   # change to your AWS region if different
# bucket = "your-tfstate-bucket-name"   # can also be passed here instead of at prompt
# key    = "3-tier-app/terraform.tfstate"
