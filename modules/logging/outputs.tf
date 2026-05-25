output "bucket_name" {
  description = "ALB logs S3 bucket name — pass this to the ALB module as alb_logs_bucket"
  value       = aws_s3_bucket.alb_logs.bucket
}

output "bucket_arn" {
  description = "ALB logs S3 bucket ARN"
  value       = aws_s3_bucket.alb_logs.arn
}
