# S3 Account-Level Public Access Block
# Enforces public access block at the AWS account level — belt-and-suspenders
# on top of individual bucket policies. Prevents any future bucket from
# accidentally being made public, even if a bucket policy allows it.

terraform {
  required_providers {
    aws = { source = "hashicorp/aws" }
  }
}

resource "aws_s3_account_public_access_block" "this" {
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
