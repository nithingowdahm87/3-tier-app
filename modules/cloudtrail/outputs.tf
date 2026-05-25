output "trail_arn"         { value = aws_cloudtrail.this.arn }
output "trail_bucket"      { value = aws_s3_bucket.trail.bucket }
output "log_group_name"    { value = aws_cloudwatch_log_group.trail.name }
output "kms_key_arn"       { value = aws_kms_key.trail.arn }
