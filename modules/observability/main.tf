terraform {
  required_providers {
    aws = { source = "hashicorp/aws" }
  }
}

# X-Ray sampling rules
resource "aws_xray_sampling_rule" "default" {
  rule_name      = "${var.name_prefix}-default"
  priority       = 10000
  reservoir_size = 5
  fixed_rate     = 0.05
  url_path       = "*"
  host           = "*"
  http_method    = "*"
  service_type   = "*"
  service_name   = "*"
  resource_arn   = "*"
  version        = 1
}

# Kinesis Firehose -> S3 for centralised log aggregation
resource "aws_s3_bucket" "logs" {
  bucket        = var.logs_bucket_name
  force_destroy = false
  tags          = merge(var.tags, { Name = var.logs_bucket_name })
}

resource "aws_s3_bucket_public_access_block" "logs" {
  bucket                  = aws_s3_bucket.logs.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "logs" {
  bucket = aws_s3_bucket.logs.id
  rule {
    apply_server_side_encryption_by_default { sse_algorithm = "AES256" }
  }
}

resource "aws_iam_role" "firehose" {
  name = "${var.name_prefix}-firehose-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{ Action = "sts:AssumeRole" Effect = "Allow" Principal = { Service = "firehose.amazonaws.com" } }]
  })
}

resource "aws_iam_role_policy" "firehose" {
  role = aws_iam_role.firehose.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = ["s3:AbortMultipartUpload", "s3:GetBucketLocation", "s3:GetObject", "s3:ListBucket", "s3:ListBucketMultipartUploads", "s3:PutObject"]
      Resource = [aws_s3_bucket.logs.arn, "${aws_s3_bucket.logs.arn}/*"]
    }]
  })
}

resource "aws_kinesis_firehose_delivery_stream" "logs" {
  name        = "${var.name_prefix}-log-delivery"
  destination = "extended_s3"

  extended_s3_configuration {
    role_arn            = aws_iam_role.firehose.arn
    bucket_arn          = aws_s3_bucket.logs.arn
    prefix              = "logs/year=!{timestamp:yyyy}/month=!{timestamp:MM}/day=!{timestamp:dd}/"
    error_output_prefix = "errors/year=!{timestamp:yyyy}/month=!{timestamp:MM}/day=!{timestamp:dd}/!{firehose:error-output-type}/"
    buffering_size      = 64
    buffering_interval  = 300
    compression_format  = "GZIP"
  }

  tags = var.tags
}

# Athena for SQL querying over S3 logs
resource "aws_athena_workgroup" "logs" {
  name = "${var.name_prefix}-logs"

  configuration {
    enforce_workgroup_configuration    = true
    publish_cloudwatch_metrics_enabled = true

    result_configuration {
      output_location = "s3://${aws_s3_bucket.logs.bucket}/athena-results/"
    }
  }

  tags = var.tags
}

# ---- CloudWatch Dashboard -------------------------------------------------
# Core widgets are always created.
# The WAF Blocked Requests widget is optional: it is included only when
# var.waf_acl_name is non-empty, which breaks the circular dependency that
# previously existed between this module and modules/waf.

locals {
  core_widgets = [
    {
      type = "metric"
      properties = {
        title   = "ALB 5xx Errors"
        period  = 300
        stat    = "Sum"
        metrics = [["AWS/ApplicationELB", "HTTPCode_ELB_5XX_Count", "LoadBalancer", var.alb_arn_suffix]]
      }
    },
    {
      type = "metric"
      properties = {
        title   = "ALB p99 Latency (s)"
        period  = 300
        stat    = "p99"
        metrics = [["AWS/ApplicationELB", "TargetResponseTime", "LoadBalancer", var.alb_arn_suffix]]
      }
    },
    {
      type = "metric"
      properties = {
        title   = "Web ASG CPU"
        period  = 300
        stat    = "Average"
        metrics = [["AWS/EC2", "CPUUtilization", "AutoScalingGroupName", var.web_asg_name]]
      }
    },
    {
      type = "metric"
      properties = {
        title   = "App ASG CPU"
        period  = 300
        stat    = "Average"
        metrics = [["AWS/EC2", "CPUUtilization", "AutoScalingGroupName", var.app_asg_name]]
      }
    },
    {
      type = "metric"
      properties = {
        title   = "Aurora DB Connections"
        period  = 300
        stat    = "Average"
        metrics = [["AWS/RDS", "DatabaseConnections", "DBClusterIdentifier", var.aurora_cluster_id]]
      }
    },
    {
      type = "metric"
      properties = {
        title   = "Aurora Replica Lag (ms)"
        period  = 60
        stat    = "Maximum"
        metrics = [["AWS/RDS", "AuroraGlobalDBReplicationLag"]]
      }
    },
    {
      type = "metric"
      properties = {
        title   = "DynamoDB Throttled Requests"
        period  = 300
        stat    = "Sum"
        metrics = [["AWS/DynamoDB", "ThrottledRequests", "TableName", var.dynamodb_table_name]]
      }
    },
  ]

  waf_widget = var.waf_acl_name != "" ? [{
    type = "metric"
    properties = {
      title   = "WAF Blocked Requests"
      period  = 300
      stat    = "Sum"
      metrics = [["AWS/WAFV2", "BlockedRequests", "WebACL", var.waf_acl_name, "Region", var.region, "Rule", "ALL"]]
    }
  }] : []
}

resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = "${var.name_prefix}-operations"
  dashboard_body = jsonencode({ widgets = concat(local.core_widgets, local.waf_widget) })
}
