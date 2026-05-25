terraform {
  required_providers {
    aws = { source = "hashicorp/aws" }
  }
}

# Central SNS topic for all ops alerts
resource "aws_sns_topic" "ops" {
  name              = "${var.name_prefix}-ops-alerts"
  kms_master_key_id = "alias/aws/sns"
  tags              = merge(var.tags, { Name = "${var.name_prefix}-ops-alerts" })
}

resource "aws_sns_topic_subscription" "email" {
  count     = var.alert_email != "" ? 1 : 0
  topic_arn = aws_sns_topic.ops.arn
  protocol  = "email"
  endpoint  = var.alert_email
}

# ALB Alarms
resource "aws_cloudwatch_metric_alarm" "alb_5xx" {
  alarm_name          = "${var.name_prefix}-alb-5xx-rate"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "HTTPCode_Target_5XX_Count"
  namespace           = "AWS/ApplicationELB"
  period              = 300
  statistic           = "Sum"
  threshold           = var.alb_5xx_threshold
  alarm_description   = "ALB 5xx errors exceeded threshold"
  alarm_actions       = [aws_sns_topic.ops.arn]
  ok_actions          = [aws_sns_topic.ops.arn]
  dimensions          = { LoadBalancer = var.alb_arn_suffix }
}

resource "aws_cloudwatch_metric_alarm" "alb_latency_p99" {
  alarm_name          = "${var.name_prefix}-alb-latency-p99"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  extended_statistic  = "p99"
  metric_name         = "TargetResponseTime"
  namespace           = "AWS/ApplicationELB"
  period              = 300
  threshold           = 2
  alarm_description   = "ALB p99 latency > 2s"
  alarm_actions       = [aws_sns_topic.ops.arn]
  dimensions          = { LoadBalancer = var.alb_arn_suffix }
}

# Aurora Alarms
resource "aws_cloudwatch_metric_alarm" "aurora_replica_lag" {
  alarm_name          = "${var.name_prefix}-aurora-replica-lag"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 3
  metric_name         = "AuroraGlobalDBReplicationLag"
  namespace           = "AWS/RDS"
  period              = 60
  statistic           = "Maximum"
  threshold           = 30000
  alarm_description   = "Aurora global replication lag > 30s"
  alarm_actions       = [aws_sns_topic.ops.arn]
  dimensions          = { DBClusterIdentifier = var.aurora_cluster_id }
}

resource "aws_cloudwatch_metric_alarm" "aurora_connections" {
  alarm_name          = "${var.name_prefix}-aurora-connections"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "DatabaseConnections"
  namespace           = "AWS/RDS"
  period              = 300
  statistic           = "Maximum"
  threshold           = var.aurora_max_connections
  alarm_description   = "Aurora connections near limit"
  alarm_actions       = [aws_sns_topic.ops.arn]
  dimensions          = { DBClusterIdentifier = var.aurora_cluster_id }
}

# DynamoDB throttle alarm
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
  alarm_actions       = [aws_sns_topic.ops.arn]
  dimensions          = { TableName = var.dynamodb_table_name }
}

# ASG healthy host alarm
resource "aws_cloudwatch_metric_alarm" "asg_healthy_hosts" {
  alarm_name          = "${var.name_prefix}-asg-unhealthy-hosts"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 2
  metric_name         = "HealthyHostCount"
  namespace           = "AWS/ApplicationELB"
  period              = 60
  statistic           = "Minimum"
  threshold           = var.min_healthy_hosts
  alarm_description   = "Healthy host count below minimum"
  alarm_actions       = [aws_sns_topic.ops.arn]
  dimensions = {
    LoadBalancer = var.alb_arn_suffix
    TargetGroup  = var.web_tg_arn_suffix
  }
}

# ASG SNS notifications (launch/terminate events)
resource "aws_autoscaling_notification" "web" {
  group_names = var.asg_names
  notifications = [
    "autoscaling:EC2_INSTANCE_LAUNCH",
    "autoscaling:EC2_INSTANCE_TERMINATE",
    "autoscaling:EC2_INSTANCE_LAUNCH_ERROR",
    "autoscaling:EC2_INSTANCE_TERMINATE_ERROR",
  ]
  topic_arn = aws_sns_topic.ops.arn
}
