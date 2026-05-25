terraform {
  required_providers {
    aws = {
      source                = "hashicorp/aws"
      configuration_aliases = [aws.primary, aws.secondary]
    }
  }
}

resource "aws_guardduty_detector" "primary" {
  provider = aws.primary
  enable   = true

  datasources {
    s3_logs { enable = true }
    kubernetes { audit_logs { enable = false } }
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

# SNS notification for HIGH/CRITICAL GuardDuty findings via EventBridge
resource "aws_cloudwatch_event_rule" "guardduty_findings" {
  provider    = aws.primary
  name        = "${var.name_prefix}-guardduty-high-findings"
  description = "Capture HIGH and CRITICAL GuardDuty findings"

  event_pattern = jsonencode({
    source      = ["aws.guardduty"]
    detail-type = ["GuardDuty Finding"]
    detail      = { severity = [{ numeric = [">=", 7] }] }
  })
}

resource "aws_cloudwatch_event_target" "guardduty_sns" {
  provider  = aws.primary
  rule      = aws_cloudwatch_event_rule.guardduty_findings.name
  target_id = "GuardDutySNS"
  arn       = var.alerts_sns_topic_arn
}
