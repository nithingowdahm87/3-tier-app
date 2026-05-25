output "rule_arns" {
  description = "Map of Config rule name → ARN"
  value = {
    s3_encryption        = aws_config_config_rule.s3_server_side_encryption.arn
    s3_ssl_only          = aws_config_config_rule.s3_ssl_only.arn
    s3_versioning        = aws_config_config_rule.s3_versioning.arn
    ebs_encrypted        = aws_config_config_rule.ebs_encrypted.arn
    ec2_no_public_ip     = aws_config_config_rule.ec2_no_public_ip.arn
    rds_encrypted        = aws_config_config_rule.rds_storage_encrypted.arn
    rds_deletion_protect = aws_config_config_rule.rds_deletion_protection.arn
    required_tags        = aws_config_config_rule.required_tags.arn
    nacl_ssh             = aws_config_config_rule.nacl_no_unrestricted_ssh.arn
    alb_waf              = aws_config_config_rule.alb_waf_enabled.arn
    cloudtrail_kms       = aws_config_config_rule.cloudtrail_encryption.arn
    kms_rotation         = aws_config_config_rule.kms_key_rotation.arn
    iam_no_inline        = aws_config_config_rule.iam_no_inline_policy.arn
    iam_user_no_policies = aws_config_config_rule.iam_user_no_policies.arn
  }
}
