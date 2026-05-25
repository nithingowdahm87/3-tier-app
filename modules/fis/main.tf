terraform {
  required_providers {
    aws = { source = "hashicorp/aws" }
  }
}

# IAM role for FIS experiments
resource "aws_iam_role" "fis" {
  name = "${var.name_prefix}-fis-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "fis.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "fis" {
  role = aws_iam_role.fis.name
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ec2:DescribeInstances",
          "ec2:TerminateInstances",
          "ec2:StopInstances",
          "autoscaling:DescribeAutoScalingGroups",
          "rds:FailoverDBCluster",
          "rds:DescribeDBClusters",
          "cloudwatch:DescribeAlarms",
          "logs:CreateLogDelivery",
          "logs:PutLogEvents"
        ]
        Resource = "*"
      }
    ]
  })
}

# Experiment 1: Terminate random EC2 instance in web ASG (validate self-healing)
resource "aws_fis_experiment_template" "ec2_terminate" {
  description = "Terminate a random web-tier EC2 instance — validate ASG self-healing"
  role_arn    = aws_iam_role.fis.arn

  stop_condition {
    source = "aws:cloudwatch:alarm"
    value  = var.stop_alarm_arn
  }

  action {
    name      = "terminate-instance"
    action_id = "aws:ec2:terminate-instances"
    target { key = "Instances", value = "web-instances" }
  }

  target {
    name           = "web-instances"
    resource_type  = "aws:ec2:instance"
    selection_mode = "COUNT(1)"
    resource_tag {
      key   = "aws:autoscaling:groupName"
      value = var.web_asg_name
    }
  }

  tags = merge(var.tags, { Name = "${var.name_prefix}-fis-ec2-terminate" })
}

# Experiment 2: Aurora cluster failover (validate reader promotion)
resource "aws_fis_experiment_template" "aurora_failover" {
  description = "Failover Aurora primary cluster — validate reader promotion time"
  role_arn    = aws_iam_role.fis.arn

  stop_condition {
    source = "none"
    value  = ""
  }

  action {
    name      = "failover-aurora"
    action_id = "aws:rds:failover-db-cluster"
    target { key = "Clusters", value = "aurora-primary" }
  }

  target {
    name           = "aurora-primary"
    resource_type  = "aws:rds:cluster"
    selection_mode = "ALL"
    resource_tag {
      key   = "Name"
      value = "${var.name_prefix}-aurora-primary"
    }
  }

  tags = merge(var.tags, { Name = "${var.name_prefix}-fis-aurora-failover" })
}
