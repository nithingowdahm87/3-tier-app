provider "aws" {
  region = var.primary_region
}

# Customer-managed KMS key for state bucket
resource "aws_kms_key" "tfstate" {
  description             = "KMS key for Terraform state bucket encryption"
  deletion_window_in_days = 10
  enable_key_rotation     = true

  tags = {
    Name      = "terraform-state-kms"
    ManagedBy = "terraform"
  }

  lifecycle {
    prevent_destroy = true  # never accidentally destroy the state encryption key
  }
}

resource "aws_kms_alias" "tfstate" {
  name          = "alias/terraform-state"
  target_key_id = aws_kms_key.tfstate.key_id
}

resource "aws_s3_bucket" "tfstate" {
  bucket        = var.state_bucket_name
  force_destroy = false

  tags = {
    Name        = "terraform-state"
    Environment = "prod"
    ManagedBy   = "terraform"
  }

  lifecycle {
    prevent_destroy = true  # never accidentally destroy the state bucket
  }
}

resource "aws_s3_bucket_versioning" "tfstate" {
  bucket = aws_s3_bucket.tfstate.id
  versioning_configuration { status = "Enabled" }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "tfstate" {
  bucket = aws_s3_bucket.tfstate.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.tfstate.arn
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_public_access_block" "tfstate" {
  bucket                  = aws_s3_bucket.tfstate.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# HTTPS-only bucket policy
resource "aws_s3_bucket_policy" "tfstate_https_only" {
  bucket = aws_s3_bucket.tfstate.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "DenyNonHTTPS"
        Effect    = "Deny"
        Principal = "*"
        Action    = "s3:*"
        Resource  = [
          aws_s3_bucket.tfstate.arn,
          "${aws_s3_bucket.tfstate.arn}/*"
        ]
        Condition = {
          Bool = { "aws:SecureTransport" = "false" }
        }
      }
    ]
  })
}

# NOTE: DynamoDB lock table removed — using S3 native locking (use_lockfile=true)
# Requires Terraform >= 1.10. S3 bucket versioning above is the prerequisite.
# If you have an existing aws_dynamodb_table.tflock, run:
#   terraform destroy -target=aws_dynamodb_table.tflock
# before removing it from this file.

output "state_bucket" { value = aws_s3_bucket.tfstate.bucket }
output "kms_key_arn"  { value = aws_kms_key.tfstate.arn }
