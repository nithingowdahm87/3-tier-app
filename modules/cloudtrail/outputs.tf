output "cloudtrail_arn"    { value = aws_cloudtrail.this.arn }
output "cloudtrail_bucket" { value = aws_s3_bucket.cloudtrail.bucket }
output "kms_key_arn"       { value = aws_kms_key.cloudtrail.arn }
