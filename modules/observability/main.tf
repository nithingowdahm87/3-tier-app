terraform {
  required_providers {
    aws = { source = "hashicorp/aws" }
  }
}

# resource "aws_xray_sampling_rule" "default" {
#   rule_name      = "${var.name_prefix}-default"
#   priority       = 9999
#   reservoir_size = 5
#   fixed_rate     = 0.05
#   url_path       = "*"
#   host           = "*"
#   http_method    = "*"
#   service_type   = "*"
#   service_name   = "*"
#   resource_arn   = "*"
#   version        = 1
# }

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
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}


# resource "aws_athena_workgroup" "logs" {
#   name = "${var.name_prefix}-logs"
# 
#   configuration {
#     enforce_workgroup_configuration    = true
#     publish_cloudwatch_metrics_enabled = true
# 
#     result_configuration {
#       output_location = "s3://${aws_s3_bucket.logs.bucket}/athena-results/"
#     }
#   }
# 
#   tags = var.tags
# }

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
        title   = "RDS DB Connections"
        period  = 300
        stat    = "Average"
        metrics = [["AWS/RDS", "DatabaseConnections", "DBInstanceIdentifier", var.db_instance_id]]
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
