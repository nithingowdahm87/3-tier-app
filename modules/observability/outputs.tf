output "firehose_arn"       { value = "" }
output "logs_bucket_name"   { value = aws_s3_bucket.logs.bucket }
output "athena_workgroup"   { value = aws_athena_workgroup.logs.name }
output "dashboard_name"     { value = aws_cloudwatch_dashboard.main.dashboard_name }
