terraform {
  required_providers {
    aws = { source = "hashicorp/aws" }
  }
}

resource "aws_iam_role" "fis" {
  name = "${var.name_prefix}-fis-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{ Action = "sts:AssumeRole" Effect = "Allow" Principal = { Service = "fis.amazonaws.com" } }]
  })
}

resource "aws_iam_role_policy" "fis" {
  role = aws_iam_role.fis.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = ["ec2:TerminateInstances", "ec2:StopInstances", "ec2:DescribeInstances"]
        Resource = "*"
        Condition = { StringEquals = { "ec2:ResourceTag/Environment" = var.environment } }
      },
      {
        Effect   = "Allow"
        Action   = ["rds:FailoverDBCluster", "rds:DescribeDBClusters"]
        Resource = "*"
      },
      {
        Effect   = "Allow"
        Action   = ["cloudwatch:DescribeAlarms"]
        Resource = "*"
      },
      {
        Effect   = "Allow"
        Action   = ["ssm:SendCommand", "ssm:GetCommandInvocation"]
        Resource = "*"
      }
    ]
  })
}

# Experiment 1: Terminate random web-tier EC2 instance (validate ASG self-healing)
resource "aws_fis_experiment_template" "terminate_web_instance" {
  description = "Terminate a random web-tier EC2 to validate ASG self-healing"
  role_arn    = aws_iam_role.fis.arn

  stop_condition {
    source = "aws:cloudwatch:alarm"
    value  = var.healthy_hosts_alarm_arn
  }

  action {
    name        = "terminate-web-instance"
    action_id   = "aws:ec2:terminate-instances"
    target { key = "Instances" value = "web-instances" }
  }

  target {
    name           = "web-instances"
    resource_type  = "aws:ec2:instance"
    selection_mode = "COUNT(1)"
    resource_tag { key = "Role" value = "web" }
    resource_tag { key = "Environment" value = var.environment }
  }

  tags = merge(var.tags, { Name = "${var.name_prefix}-terminate-web" })
}

# Experiment 2: Aurora global cluster failover drill
resource "aws_fis_experiment_template" "aurora_failover" {
  description = "Trigger Aurora global cluster failover to secondary region"
  role_arn    = aws_iam_role.fis.arn

  stop_condition { source = "none" }

  action {
    name      = "aurora-failover"
    action_id = "aws:rds:failover-db-cluster"
    target { key = "Clusters" value = "aurora-primary" }
  }

  target {
    name           = "aurora-primary"
    resource_type  = "aws:rds:cluster"
    selection_mode = "ALL"
    resource_arn   = [var.aurora_cluster_arn]
  }

  tags = merge(var.tags, { Name = "${var.name_prefix}-aurora-failover" })
}
