terraform {
  required_providers {
    aws = { source = "hashicorp/aws" }
  }
}

data "aws_caller_identity" "current" {}

resource "aws_s3_bucket" "config" {
  bucket        = var.bucket_name
  force_destroy = true
  tags          = merge(var.tags, { Name = var.bucket_name })
}

resource "aws_s3_bucket_public_access_block" "config" {
  bucket                  = aws_s3_bucket.config.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_policy" "config" {
  bucket = aws_s3_bucket.config.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AWSConfigBucketPermissionsCheck"
        Effect    = "Allow"
        Principal = { Service = "config.amazonaws.com" }
        Action    = "s3:GetBucketAcl"
        Resource  = aws_s3_bucket.config.arn
      },
      {
        Sid       = "AWSConfigBucketDelivery"
        Effect    = "Allow"
        Principal = { Service = "config.amazonaws.com" }
        Action    = "s3:PutObject"
        Resource  = "${aws_s3_bucket.config.arn}/AWSLogs/${data.aws_caller_identity.current.account_id}/Config/*"
        Condition = { StringEquals = { "s3:x-amz-acl" = "bucket-owner-full-control" } }
      }
    ]
  })
}

resource "aws_iam_role" "config" {
  name_prefix = "${var.name_prefix}-config-role-"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "config.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "config" {
  role       = aws_iam_role.config.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWS_ConfigRole"
}

resource "aws_config_configuration_recorder" "this" {
  name     = "${var.name_prefix}-config-recorder"
  role_arn = aws_iam_role.config.arn

  recording_group {
    all_supported                 = true
    include_global_resource_types = true
  }
}

resource "aws_config_delivery_channel" "this" {
  name           = "${var.name_prefix}-config-delivery"
  s3_bucket_name = aws_s3_bucket.config.id
  depends_on     = [aws_config_configuration_recorder.this]
}

resource "aws_config_configuration_recorder_status" "this" {
  name       = aws_config_configuration_recorder.this.name
  is_enabled = true
  depends_on = [aws_config_delivery_channel.this]
}

locals {
  managed_rules = {
    "restricted-ssh"                    = "INCOMING_SSH_DISABLED"
    "vpc-default-security-group-closed" = "VPC_DEFAULT_SECURITY_GROUP_CLOSED"
    "s3-bucket-public-read-prohibited"  = "S3_BUCKET_PUBLIC_READ_PROHIBITED"
    "encrypted-volumes"                 = "ENCRYPTED_VOLUMES"
    "rds-storage-encrypted"             = "RDS_STORAGE_ENCRYPTED"
    "rds-instance-public-access-check"  = "RDS_INSTANCE_PUBLIC_ACCESS_CHECK"
    "iam-password-policy"               = "IAM_PASSWORD_POLICY"
    "root-account-mfa-enabled"          = "ROOT_ACCOUNT_MFA_ENABLED"
    "cloudtrail-enabled"                = "CLOUD_TRAIL_ENABLED"
    "multi-region-cloudtrail-enabled"   = "MULTI_REGION_CLOUD_TRAIL_ENABLED"
  }
}

resource "aws_config_config_rule" "managed" {
  for_each = local.managed_rules

  name = "${var.name_prefix}-${each.key}"

  source {
    owner             = "AWS"
    source_identifier = each.value
  }

  depends_on = [aws_config_configuration_recorder_status.this]
}
