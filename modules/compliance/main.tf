terraform {
  required_providers {
    aws = { source = "hashicorp/aws" }
  }
}

# ─── Additional Config Managed Rules ─────────────────────────────────────────

resource "aws_config_config_rule" "s3_server_side_encryption" {
  name        = "${var.name_prefix}-s3-server-side-encryption-enabled"
  description = "Checks that S3 buckets have server-side encryption enabled"

  source {
    owner             = "AWS"
    source_identifier = "S3_BUCKET_SERVER_SIDE_ENCRYPTION_ENABLED"
  }

  depends_on = [var.config_recorder_id]
}

resource "aws_config_config_rule" "s3_ssl_only" {
  name        = "${var.name_prefix}-s3-bucket-ssl-requests-only"
  description = "Checks that S3 buckets have a policy requiring SSL/TLS"

  source {
    owner             = "AWS"
    source_identifier = "S3_BUCKET_SSL_REQUESTS_ONLY"
  }

  depends_on = [var.config_recorder_id]
}

resource "aws_config_config_rule" "s3_versioning" {
  name        = "${var.name_prefix}-s3-bucket-versioning-enabled"
  description = "Checks that S3 buckets have versioning enabled"

  source {
    owner             = "AWS"
    source_identifier = "S3_BUCKET_VERSIONING_ENABLED"
  }

  depends_on = [var.config_recorder_id]
}

resource "aws_config_config_rule" "ebs_encrypted" {
  name        = "${var.name_prefix}-ec2-ebs-encryption-by-default"
  description = "Checks that EBS encryption by default is enabled"

  source {
    owner             = "AWS"
    source_identifier = "EC2_EBS_ENCRYPTION_BY_DEFAULT"
  }

  depends_on = [var.config_recorder_id]
}

resource "aws_config_config_rule" "ec2_no_public_ip" {
  name        = "${var.name_prefix}-ec2-instance-no-public-ip"
  description = "Checks that EC2 instances are not directly associated with a public IP"

  source {
    owner             = "AWS"
    source_identifier = "EC2_INSTANCE_NO_PUBLIC_IP"
  }

  depends_on = [var.config_recorder_id]
}

resource "aws_config_config_rule" "rds_storage_encrypted" {
  name        = "${var.name_prefix}-rds-storage-encrypted"
  description = "Checks that RDS DB instances have storage encryption enabled"

  source {
    owner             = "AWS"
    source_identifier = "RDS_STORAGE_ENCRYPTED"
  }

  depends_on = [var.config_recorder_id]
}

resource "aws_config_config_rule" "rds_deletion_protection" {
  name        = "${var.name_prefix}-rds-instance-deletion-protection-enabled"
  description = "Checks that RDS clusters have deletion protection enabled"

  source {
    owner             = "AWS"
    source_identifier = "RDS_INSTANCE_DELETION_PROTECTION_ENABLED"
  }

  depends_on = [var.config_recorder_id]
}

resource "aws_config_config_rule" "required_tags" {
  name        = "${var.name_prefix}-required-tags"
  description = "Checks that required tags are applied to all supported resources"

  source {
    owner             = "AWS"
    source_identifier = "REQUIRED_TAGS"
  }

  input_parameters = jsonencode({
    tag1Key   = "Environment"
    tag2Key   = "Project"
    tag3Key   = "ManagedBy"
    tag4Key   = "Owner"
    tag5Key   = "CostCenter"
  })

  scope {
    compliance_resource_types = [
      "AWS::EC2::Instance",
      "AWS::RDS::DBInstance",
      "AWS::S3::Bucket",
      "AWS::ElastiCache::ReplicationGroup",
      "AWS::DynamoDB::Table",
      "AWS::ElasticLoadBalancingV2::LoadBalancer",
    ]
  }

  depends_on = [var.config_recorder_id]
}

resource "aws_config_config_rule" "nacl_no_unrestricted_ssh" {
  name        = "${var.name_prefix}-nacl-no-unrestricted-ssh-rdp"
  description = "Checks NACL do not allow unrestricted SSH or RDP inbound"

  source {
    owner             = "AWS"
    source_identifier = "NACL_NO_UNRESTRICTED_SSH_RDP"
  }

  depends_on = [var.config_recorder_id]
}

resource "aws_config_config_rule" "alb_waf_enabled" {
  name        = "${var.name_prefix}-alb-waf-enabled"
  description = "Checks that ALBs have WAF enabled"

  source {
    owner             = "AWS"
    source_identifier = "ALB_WAF_ENABLED"
  }

  depends_on = [var.config_recorder_id]
}

resource "aws_config_config_rule" "cloudtrail_encryption" {
  name        = "${var.name_prefix}-cloudtrail-encryption-enabled"
  description = "Checks that CloudTrail trails are encrypted with KMS"

  source {
    owner             = "AWS"
    source_identifier = "CLOUD_TRAIL_ENCRYPTION_ENABLED"
  }

  depends_on = [var.config_recorder_id]
}

resource "aws_config_config_rule" "kms_key_rotation" {
  name        = "${var.name_prefix}-cmk-backing-key-rotation-enabled"
  description = "Checks that KMS CMK rotation is enabled"

  source {
    owner             = "AWS"
    source_identifier = "CMK_BACKING_KEY_ROTATION_ENABLED"
  }

  depends_on = [var.config_recorder_id]
}

resource "aws_config_config_rule" "iam_no_inline_policy" {
  name        = "${var.name_prefix}-iam-no-inline-policy-check"
  description = "Checks that IAM users, roles, and groups have no inline policies"

  source {
    owner             = "AWS"
    source_identifier = "IAM_NO_INLINE_POLICY_CHECK"
  }

  depends_on = [var.config_recorder_id]
}

resource "aws_config_config_rule" "iam_user_no_policies" {
  name        = "${var.name_prefix}-iam-user-no-policies-check"
  description = "Checks that IAM users have no directly-attached managed policies (use groups/roles)"

  source {
    owner             = "AWS"
    source_identifier = "IAM_USER_NO_POLICIES_CHECK"
  }

  depends_on = [var.config_recorder_id]
}
