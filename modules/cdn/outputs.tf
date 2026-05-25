output "cloudfront_domain_name"   { value = aws_cloudfront_distribution.this.domain_name }
output "cloudfront_distribution_id" { value = aws_cloudfront_distribution.this.id }
output "static_bucket_name"       { value = aws_s3_bucket.static.bucket }
output "static_bucket_arn"        { value = aws_s3_bucket.static.arn }
