terraform {
  required_providers {
    aws = { source = "hashicorp/aws" }
  }
}

# Security Hub — aggregates GuardDuty, Config, Inspector findings
resource "aws_securityhub_account" "this" {}

# Enable AWS Foundational Security Best Practices standard
resource "aws_securityhub_standards_subscription" "fsbp" {
  standards_arn = "arn:aws:securityhub:${var.primary_region}::standards/aws-foundational-security-best-practices/v/1.0.0"
  depends_on    = [aws_securityhub_account.this]
}

# Enable CIS AWS Foundations Benchmark
resource "aws_securityhub_standards_subscription" "cis" {
  standards_arn = "arn:aws:securityhub:::ruleset/cis-aws-foundations-benchmark/v/1.2.0"
  depends_on    = [aws_securityhub_account.this]
}

# EventBridge rule to forward CRITICAL findings to SNS
resource "aws_cloudwatch_event_rule" "securityhub_critical" {
  name        = "${var.name_prefix}-securityhub-critical"
  description = "Forward CRITICAL Security Hub findings to SNS"

  event_pattern = jsonencode({
    source      = ["aws.securityhub"]
    detail-type = ["Security Hub Findings - Imported"]
    detail = {
      findings = {
        Severity = { Label = ["CRITICAL", "HIGH"] }
        Workflow  = { Status = ["NEW"] }
      }
    }
  })
}

resource "aws_cloudwatch_event_target" "securityhub_sns" {
  rule      = aws_cloudwatch_event_rule.securityhub_critical.name
  target_id = "securityhub-sns"
  arn       = var.sns_topic_arn
}
