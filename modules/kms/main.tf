# KMS Customer Managed Keys (CMK)
# One CMK per data store for independent key rotation + audit trail.
# All keys auto-rotate every 365 days.

terraform {
  required_providers {
    aws = { source = "hashicorp/aws" }
  }
}

resource "aws_kms_key" "aurora" {
  description             = "CMK for Aurora cluster encryption — ${var.name_prefix}"
  deletion_window_in_days = 30
  enable_key_rotation     = true
  tags                    = merge(var.tags, { Name = "${var.name_prefix}-aurora-cmk" })
}

resource "aws_kms_alias" "aurora" {
  name          = "alias/${var.name_prefix}-aurora"
  target_key_id = aws_kms_key.aurora.key_id
}

resource "aws_kms_key" "s3" {
  description             = "CMK for S3 bucket encryption — ${var.name_prefix}"
  deletion_window_in_days = 30
  enable_key_rotation     = true
  tags                    = merge(var.tags, { Name = "${var.name_prefix}-s3-cmk" })
}

resource "aws_kms_alias" "s3" {
  name          = "alias/${var.name_prefix}-s3"
  target_key_id = aws_kms_key.s3.key_id
}

resource "aws_kms_key" "dynamodb" {
  description             = "CMK for DynamoDB table encryption — ${var.name_prefix}"
  deletion_window_in_days = 30
  enable_key_rotation     = true
  tags                    = merge(var.tags, { Name = "${var.name_prefix}-dynamodb-cmk" })
}

resource "aws_kms_alias" "dynamodb" {
  name          = "alias/${var.name_prefix}-dynamodb"
  target_key_id = aws_kms_key.dynamodb.key_id
}

resource "aws_kms_key" "elasticache" {
  description             = "CMK for ElastiCache (Redis) at-rest encryption — ${var.name_prefix}"
  deletion_window_in_days = 30
  enable_key_rotation     = true
  tags                    = merge(var.tags, { Name = "${var.name_prefix}-elasticache-cmk" })
}

resource "aws_kms_alias" "elasticache" {
  name          = "alias/${var.name_prefix}-elasticache"
  target_key_id = aws_kms_key.elasticache.key_id
}

resource "aws_kms_key" "secretsmanager" {
  description             = "CMK for Secrets Manager secrets — ${var.name_prefix}"
  deletion_window_in_days = 30
  enable_key_rotation     = true
  tags                    = merge(var.tags, { Name = "${var.name_prefix}-secrets-cmk" })
}

resource "aws_kms_alias" "secretsmanager" {
  name          = "alias/${var.name_prefix}-secretsmanager"
  target_key_id = aws_kms_key.secretsmanager.key_id
}

resource "aws_kms_key" "ebs" {
  description             = "CMK for EBS volume encryption — ${var.name_prefix}"
  deletion_window_in_days = 30
  enable_key_rotation     = true
  tags                    = merge(var.tags, { Name = "${var.name_prefix}-ebs-cmk" })
}

resource "aws_kms_alias" "ebs" {
  name          = "alias/${var.name_prefix}-ebs"
  target_key_id = aws_kms_key.ebs.key_id
}
