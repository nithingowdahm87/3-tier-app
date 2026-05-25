terraform {
  required_providers {
    aws = { source = "hashicorp/aws" }
  }
}

data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

# ─── NAT Gateway — Active Connection Count (proxy for saturation) ─────────────

resource "aws_cloudwatch_metric_alarm" "nat_active_connections" {
  for_each = toset(var.nat_gateway_ids)

  alarm_name          = "${var.name_prefix}-nat-${each.key}-active-connections-high"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 3
  metric_name         = "ActiveConnectionCount"
  namespace           = "AWS/NATGateway"
  period              = 60
  statistic           = "Maximum"
  threshold           = var.nat_connection_threshold
  alarm_description   = "NAT Gateway ${each.key} active connections ≥ ${var.nat_connection_threshold} for 3 consecutive minutes"
  alarm_actions       = [var.sns_topic_arn]
  ok_actions          = [var.sns_topic_arn]
  treat_missing_data  = "notBreaching"

  dimensions = { NatGatewayId = each.key }

  tags = var.tags
}

resource "aws_cloudwatch_metric_alarm" "nat_packet_drop" {
  for_each = toset(var.nat_gateway_ids)

  alarm_name          = "${var.name_prefix}-nat-${each.key}-packet-drop"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "PacketDropCount"
  namespace           = "AWS/NATGateway"
  period              = 300
  statistic           = "Sum"
  threshold           = var.nat_packet_drop_threshold
  alarm_description   = "NAT Gateway ${each.key} is dropping packets — possible saturation or quota limit approaching"
  alarm_actions       = [var.sns_topic_arn]
  ok_actions          = [var.sns_topic_arn]
  treat_missing_data  = "notBreaching"

  dimensions = { NatGatewayId = each.key }

  tags = var.tags
}

# ─── KMS — Request errors and throttles ───────────────────────────────────────

resource "aws_cloudwatch_metric_alarm" "kms_throttles" {
  alarm_name          = "${var.name_prefix}-kms-throttled-requests"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 2
  metric_name         = "ThrottledRequests"
  namespace           = "AWS/KMS"
  period              = 300
  statistic           = "Sum"
  threshold           = var.kms_throttle_threshold
  alarm_description   = "KMS throttled requests ≥ ${var.kms_throttle_threshold} in 5 min — check key usage or request rate limits"
  alarm_actions       = [var.sns_topic_arn]
  ok_actions          = [var.sns_topic_arn]
  treat_missing_data  = "notBreaching"

  tags = var.tags
}

# ─── Secrets Manager — throttles (hits service quota) ─────────────────────────

resource "aws_cloudwatch_metric_alarm" "secretsmanager_throttles" {
  alarm_name          = "${var.name_prefix}-secretsmanager-throttled"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 2
  metric_name         = "ResourceThrottledRequests"
  namespace           = "AWS/SecretsManager"
  period              = 300
  statistic           = "Sum"
  threshold           = var.secretsmanager_throttle_threshold
  alarm_description   = "Secrets Manager throttled requests ≥ ${var.secretsmanager_throttle_threshold} — may indicate hitting TPS quota"
  alarm_actions       = [var.sns_topic_arn]
  ok_actions          = [var.sns_topic_arn]
  treat_missing_data  = "notBreaching"

  tags = var.tags
}

# ─── Route53 Health Check failure alarm ───────────────────────────────────────

resource "aws_cloudwatch_metric_alarm" "route53_health_check" {
  count = var.health_check_id != "" ? 1 : 0

  alarm_name          = "${var.name_prefix}-route53-healthcheck-failed"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 1
  metric_name         = "HealthCheckStatus"
  namespace           = "AWS/Route53"
  period              = 60
  statistic           = "Minimum"
  threshold           = 1
  alarm_description   = "Route53 health check ${var.health_check_id} is UNHEALTHY — failover may be triggered"
  alarm_actions       = [var.sns_topic_arn]
  ok_actions          = [var.sns_topic_arn]
  treat_missing_data  = "breaching"

  dimensions = { HealthCheckId = var.health_check_id }

  tags = var.tags
}

# ─── ACM Certificate expiry alarm ─────────────────────────────────────────────

resource "aws_cloudwatch_metric_alarm" "acm_expiry" {
  alarm_name          = "${var.name_prefix}-acm-certificate-expiry"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 1
  metric_name         = "DaysToExpiry"
  namespace           = "AWS/CertificateManager"
  period              = 86400
  statistic           = "Minimum"
  threshold           = var.acm_expiry_days_threshold
  alarm_description   = "ACM certificate expiring in fewer than ${var.acm_expiry_days_threshold} days — check auto-renewal"
  alarm_actions       = [var.sns_topic_arn]
  ok_actions          = [var.sns_topic_arn]
  treat_missing_data  = "breaching"

  tags = var.tags
}

# ─── Lambda (rotation) error alarm ────────────────────────────────────────────

resource "aws_cloudwatch_metric_alarm" "lambda_errors" {
  count = var.rotation_lambda_name != "" ? 1 : 0

  alarm_name          = "${var.name_prefix}-rotation-lambda-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = 300
  statistic           = "Sum"
  threshold           = 0
  alarm_description   = "Secrets rotation Lambda ${var.rotation_lambda_name} errored — Aurora password rotation may have failed"
  alarm_actions       = [var.sns_topic_arn]
  treat_missing_data  = "notBreaching"

  dimensions = { FunctionName = var.rotation_lambda_name }

  tags = var.tags
}
