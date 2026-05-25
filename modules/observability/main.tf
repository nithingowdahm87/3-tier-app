terraform {
  required_providers {
    aws = { source = "hashicorp/aws" }
  }
}

# X-Ray Group for distributed tracing
resource "aws_xray_group" "this" {
  group_name        = "${var.name_prefix}-app"
  filter_expression = "service(\"${var.name_prefix}\")"
  tags              = merge(var.tags, { Name = "${var.name_prefix}-xray-group" })
}

# X-Ray sampling rule
resource "aws_xray_sampling_rule" "this" {
  rule_name      = "${var.name_prefix}-sampling"
  priority       = 9000
  version        = 1
  reservoir_size = 5
  fixed_rate     = 0.05
  url_path       = "*"
  host           = "*"
  http_method    = "*"
  service_type   = "*"
  service_name   = "*"
  resource_arn   = "*"
  tags           = var.tags
}

# Kinesis Firehose delivery stream → S3 for centralized log aggregation
resource "aws_iam_role" "firehose" {
  name = "${var.name_prefix}-firehose-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{ Effect = "Allow", Principal = { Service = "firehose.amazonaws.com" }, Action = "sts:AssumeRole" }]
  })
}

resource "aws_iam_role_policy" "firehose" {
  role = aws_iam_role.firehose.name
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["s3:PutObject", "s3:PutObjectAcl", "s3:GetBucketLocation", "s3:ListBucket"]
      Resource = [var.log_archive_bucket_arn, "${var.log_archive_bucket_arn}/*"]
    }]
  })
}

resource "aws_kinesis_firehose_delivery_stream" "logs" {
  name        = "${var.name_prefix}-log-stream"
  destination = "extended_s3"

  extended_s3_configuration {
    role_arn            = aws_iam_role.firehose.arn
    bucket_arn          = var.log_archive_bucket_arn
    prefix              = "app-logs/year=!{timestamp:yyyy}/month=!{timestamp:MM}/day=!{timestamp:dd}/"
    error_output_prefix = "errors/!{firehose:error-output-type}/"
    buffering_size      = 64
    buffering_interval  = 300
    compression_format  = "GZIP"
  }

  tags = merge(var.tags, { Name = "${var.name_prefix}-log-stream" })
}

# Athena database + workgroup for log querying
resource "aws_athena_workgroup" "logs" {
  name = "${var.name_prefix}-logs"
  configuration {
    result_configuration {
      output_location = "s3://${var.athena_results_bucket}/athena-results/"
    }
  }
  tags = merge(var.tags, { Name = "${var.name_prefix}-athena-workgroup" })
}

# CloudWatch Dashboard — MAANG single-pane-of-glass
resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = "${var.name_prefix}-operations"

  dashboard_body = jsonencode({
    widgets = [
      {
        type = "metric"
        properties = {
          title  = "ALB 5xx Error Rate"
          metrics = [["AWS/ApplicationELB", "HTTPCode_Target_5XX_Count", "LoadBalancer", var.alb_arn_suffix]]
          period = 300
          stat   = "Sum"
          view   = "timeSeries"
        }
      },
      {
        type = "metric"
        properties = {
          title  = "ALB Response Time p50/p95/p99"
          metrics = [
            ["AWS/ApplicationELB", "TargetResponseTime", "LoadBalancer", var.alb_arn_suffix, { stat = "p50", label = "p50" }],
            ["...", { stat = "p95", label = "p95" }],
            ["...", { stat = "p99", label = "p99" }]
          ]
          period = 60
          view   = "timeSeries"
        }
      },
      {
        type = "metric"
        properties = {
          title  = "ASG Instance Count"
          metrics = [
            ["AWS/AutoScaling", "GroupInServiceInstances", "AutoScalingGroupName", var.web_asg_name, { label = "Web"}],
            ["AWS/AutoScaling", "GroupInServiceInstances", "AutoScalingGroupName", var.app_asg_name, { label = "App"}]
          ]
          period = 60
          stat   = "Average"
          view   = "timeSeries"
        }
      },
      {
        type = "metric"
        properties = {
          title  = "Aurora DB Connections"
          metrics = [["AWS/RDS", "DatabaseConnections", "DBClusterIdentifier", var.aurora_cluster_id]]
          period = 60
          stat   = "Maximum"
          view   = "timeSeries"
        }
      },
      {
        type = "metric"
        properties = {
          title  = "Aurora Read/Write IOPS"
          metrics = [
            ["AWS/RDS", "ReadIOPS",  "DBClusterIdentifier", var.aurora_cluster_id, { label = "Read IOPS"}],
            ["AWS/RDS", "WriteIOPS", "DBClusterIdentifier", var.aurora_cluster_id, { label = "Write IOPS"}]
          ]
          period = 60
          stat   = "Sum"
          view   = "timeSeries"
        }
      },
      {
        type = "metric"
        properties = {
          title  = "DynamoDB Consumed Capacity"
          metrics = [
            ["AWS/DynamoDB", "ConsumedReadCapacityUnits",  "TableName", var.dynamodb_table_name, { label = "Read"}],
            ["AWS/DynamoDB", "ConsumedWriteCapacityUnits", "TableName", var.dynamodb_table_name, { label = "Write"}]
          ]
          period = 60
          stat   = "Sum"
          view   = "timeSeries"
        }
      }
    ]
  })
}
