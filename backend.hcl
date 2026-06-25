# backend.hcl – filled in with actual values
region = "ap-south-1"  # your AWS region
bucket = "nithin-3tier-prod-tfstate-969433238559"   # S3 bucket for Terraform state
key    = "3-tier-app/terraform.tfstate" # state file path within the bucket
