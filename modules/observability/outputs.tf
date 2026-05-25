output "firehose_stream_arn" { value = aws_kinesis_firehose_delivery_stream.logs.arn }
output "xray_group_arn"      { value = aws_xray_group.this.arn }
output "dashboard_name"      { value = aws_cloudwatch_dashboard.main.dashboard_name }
