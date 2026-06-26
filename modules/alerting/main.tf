terraform {
  required_providers {
    aws = { source = "hashicorp/aws" }
  }
}

# Central SNS topic for all operational alerts
resource "aws_sns_topic" "alerts" {
  name              = "${var.name_prefix}-ops-alerts"
  kms_master_key_id = "alias/aws/sns"
  tags              = merge(var.tags, { Name = "${var.name_prefix}-ops-alerts" })
}

resource "aws_sns_topic_subscription" "email" {
  count     = var.alert_email != "" ? 1 : 0
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email
}

# ALB 5xx rate alarm
resource "aws_cloudwatch_metric_alarm" "alb_5xx" {
  alarm_name          = "${var.name_prefix}-alb-5xx-rate"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "HTTPCode_ELB_5XX_Count"
  namespace           = "AWS/ApplicationELB"
  period              = 300
  statistic           = "Sum"
  threshold           = var.alb_5xx_threshold
  alarm_description   = "ALB 5xx error rate exceeded threshold"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  ok_actions          = [aws_sns_topic.alerts.arn]
  treat_missing_data  = "notBreaching"

  dimensions = { LoadBalancer = var.alb_arn_suffix }
}

# ALB p99 latency alarm
resource "aws_cloudwatch_metric_alarm" "alb_latency_p99" {
  alarm_name          = "${var.name_prefix}-alb-p99-latency"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  extended_statistic  = "p99"
  metric_name         = "TargetResponseTime"
  namespace           = "AWS/ApplicationELB"
  period              = 300
  threshold           = 2
  alarm_description   = "ALB p99 latency exceeded 2 seconds"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  treat_missing_data  = "notBreaching"

  dimensions = { LoadBalancer = var.alb_arn_suffix }
}

# Web ASG healthy host count alarm
resource "aws_cloudwatch_metric_alarm" "web_healthy_hosts" {
  alarm_name          = "${var.name_prefix}-web-healthy-hosts"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 2
  metric_name         = "HealthyHostCount"
  namespace           = "AWS/ApplicationELB"
  period              = 60
  statistic           = "Minimum"
  threshold           = var.web_min_healthy_hosts
  alarm_description   = "Web tier healthy host count dropped below minimum"
  alarm_actions       = [aws_sns_topic.alerts.arn]

  dimensions = {
    TargetGroup  = var.web_target_group_arn_suffix
    LoadBalancer = var.alb_arn_suffix
  }
}

# Aurora replica lag alarm
// Aurora replica lag alarm is not applicable for single RDS instances and has been removed.

resource "aws_cloudwatch_metric_alarm" "rds_connections" {
  alarm_name          = "${var.name_prefix}-rds-connections"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "DatabaseConnections"
  namespace           = "AWS/RDS"
  period              = 300
  statistic           = "Average"
  threshold           = var.rds_max_connections_threshold
  alarm_description   = "RDS instance connection count nearing limit"
  alarm_actions       = [aws_sns_topic.alerts.arn]

  dimensions = { DBInstanceIdentifier = var.db_instance_id }
}

# Aurora connection count alarm


# DynamoDB throttled requests alarm
resource "aws_cloudwatch_metric_alarm" "dynamodb_throttles" {
  alarm_name          = "${var.name_prefix}-dynamodb-throttles"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "ThrottledRequests"
  namespace           = "AWS/DynamoDB"
  period              = 300
  statistic           = "Sum"
  threshold           = 0
  alarm_description   = "DynamoDB throttled requests detected"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  treat_missing_data  = "notBreaching"

  dimensions = { TableName = var.dynamodb_table_name }
}

# ASG launch/terminate notifications
# resource "aws_autoscaling_notification" "web" {
#   group_names = [var.web_asg_name]
#   topic_arn   = aws_sns_topic.alerts.arn
#   notifications = [
#     "autoscaling:EC2_INSTANCE_LAUNCH",
#     "autoscaling:EC2_INSTANCE_TERMINATE",
#     "autoscaling:EC2_INSTANCE_LAUNCH_ERROR",
#     "autoscaling:EC2_INSTANCE_TERMINATE_ERROR",
#   ]
# }

# resource "aws_autoscaling_notification" "app" {
#   group_names = [var.app_asg_name]
#   topic_arn   = aws_sns_topic.alerts.arn
#   notifications = [
#     "autoscaling:EC2_INSTANCE_LAUNCH",
#     "autoscaling:EC2_INSTANCE_TERMINATE",
#     "autoscaling:EC2_INSTANCE_LAUNCH_ERROR",
#     "autoscaling:EC2_INSTANCE_TERMINATE_ERROR",
#   ]
# }
