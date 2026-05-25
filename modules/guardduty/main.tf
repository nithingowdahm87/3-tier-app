terraform {
  required_providers {
    aws = { source = "hashicorp/aws" }
  }
}

# GuardDuty — threat detection analyzing VPC Flow Logs, CloudTrail, DNS
resource "aws_guardduty_detector" "primary" {
  provider = aws.primary
  enable   = true

  datasources {
    s3_logs { enable = true }
    kubernetes { audit_logs { enable = true } }
    malware_protection {
      scan_ec2_instance_with_findings {
        ebs_volumes { enable = true }
      }
    }
  }

  tags = merge(var.tags, { Name = "${var.name_prefix}-guardduty-primary" })
}

resource "aws_guardduty_detector" "secondary" {
  provider = aws.secondary
  enable   = true

  datasources {
    s3_logs { enable = true }
    malware_protection {
      scan_ec2_instance_with_findings {
        ebs_volumes { enable = true }
      }
    }
  }

  tags = merge(var.tags, { Name = "${var.name_prefix}-guardduty-secondary" })
}

# SNS notification for HIGH/CRITICAL findings via EventBridge
resource "aws_cloudwatch_event_rule" "guardduty_findings" {
  provider    = aws.primary
  name        = "${var.name_prefix}-guardduty-findings"
  description = "Capture GuardDuty HIGH and CRITICAL findings"

  event_pattern = jsonencode({
    source      = ["aws.guardduty"]
    detail-type = ["GuardDuty Finding"]
    detail = {
      severity = [{ numeric = [">=", 7] }]
    }
  })
}

resource "aws_cloudwatch_event_target" "guardduty_sns" {
  provider  = aws.primary
  rule      = aws_cloudwatch_event_rule.guardduty_findings.name
  target_id = "guardduty-sns"
  arn       = var.sns_topic_arn
}
