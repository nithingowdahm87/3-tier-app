output "nat_connection_alarm_arns" { value = { for k, v in aws_cloudwatch_metric_alarm.nat_active_connections : k => v.arn } }
output "nat_packet_drop_alarm_arns" { value = { for k, v in aws_cloudwatch_metric_alarm.nat_packet_drop : k => v.arn } }
output "kms_throttle_alarm_arn"    { value = aws_cloudwatch_metric_alarm.kms_throttles.arn }
output "acm_expiry_alarm_arn"      { value = aws_cloudwatch_metric_alarm.acm_expiry.arn }
