provider "aws" {
  region = var.primary_region
}

# Customer-managed KMS key for state bucket + lock table encryption
resource "aws_kms_key" "tfstate" {
  description             = "KMS key for Terraform state bucket encryption"
  deletion_window_in_days = 10
  enable_key_rotation     = true

  tags = {
    Name      = "terraform-state-kms"
    ManagedBy = "terraform"
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
}

resource "aws_s3_bucket_versioning" "tfstate" {
  bucket = aws_s3_bucket.tfstate.id
  versioning_configuration {
    status = "Enabled"
  }
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

# HTTPS-only bucket policy — denies all non-TLS requests
resource "aws_s3_bucket_policy" "tfstate_https_only" {
  bucket = aws_s3_bucket.tfstate.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid       = "DenyNonHTTPS"
      Effect    = "Deny"
      Principal = "*"
      Action    = "s3:*"