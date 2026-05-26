variable "primary_region" {
  type    = string
  default = "us-east-1"
}

variable "state_bucket_name" {
  type        = string
  default     = "my-app-tfstate-prod-2026"
  description = "Name of the S3 bucket to store Terraform state. Must be globally unique."
}

# lock_table_name removed — DynamoDB lock table is no longer used.
# S3 native locking (use_lockfile=true) is used instead. Requires Terraform >= 1.10.
