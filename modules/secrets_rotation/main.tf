# Automated Secret Rotation via AWS Lambda
# Uses the AWS-managed SecretsManagerRDSMySQLRotationSingleUser Lambda rotation
# function for Aurora. Redis token rotation uses a simple custom Lambda.
# Both rotate every 30 days by default (configurable via rotation_days).

terraform {
  required_providers {
    aws = { source = "hashicorp/aws" }
  }
}

# ─── IAM Role for Rotation Lambda ────────────────────────────────────────────

resource "aws_iam_role" "rotation" {
  name = "${var.name_prefix}-secrets-rotation-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "lambda_basic" {
  role       = aws_iam_role.rotation.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "vpc_access" {
  role       = aws_iam_role.rotation.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

resource "aws_iam_role_policy" "rotation_policy" {
  name = "${var.name_prefix}-rotation-policy"
  role = aws_iam_role.rotation.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "SecretsManagerAccess"
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:PutSecretValue",
          "secretsmanager:DescribeSecret",
          "secretsmanager:UpdateSecretVersionStage",
        ]
        Resource = "*"
      },
      {
        Sid    = "KMSDecrypt"
        Effect = "Allow"
        Action = ["kms:Decrypt", "kms:GenerateDataKey"]
        Resource = var.kms_key_arn
      }
    ]
  })
}

# ─── Aurora Password Rotation Lambda ─────────────────────────────────────────
# Uses the AWS-managed RDS rotation function (no custom code needed).

resource "aws_lambda_function" "aurora_rotation" {
  count         = var.aurora_secret_arn != "" ? 1 : 0
  function_name = "${var.name_prefix}-aurora-secret-rotation"
  role          = aws_iam_role.rotation.arn

  # AWS-managed RDS MySQL single-user rotation function
  # Deploy via SAR: https://serverlessrepo.aws.amazon.com/applications/arn:aws:serverlessrepo:us-east-1:912272303299:applications~SecretsManagerRDSMySQLRotationSingleUser
  # Set this ARN after deploying the SAR application:
  filename      = "${path.module}/placeholder.zip"
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.12"
  timeout       = 30

  environment {
    variables = {
      SECRETS_MANAGER_ENDPOINT = "https://secretsmanager.${var.region}.amazonaws.com"
    }
  }

  vpc_config {
    subnet_ids         = var.subnet_ids
    security_group_ids = var.lambda_sg_ids
  }

  tags = var.tags

  lifecycle {
    ignore_changes = [filename, source_code_hash]
  }
}

resource "aws_secretsmanager_secret_rotation" "aurora" {
  count               = var.aurora_secret_arn != "" ? 1 : 0
  secret_id           = var.aurora_secret_arn
  rotation_lambda_arn = aws_lambda_function.aurora_rotation[0].arn

  rotation_rules {
    automatically_after_days = var.rotation_days
  }
}

# ─── Redis Token Rotation Lambda ──────────────────────────────────────────────

resource "aws_lambda_function" "redis_rotation" {
  count         = var.redis_secret_arn != "" ? 1 : 0
  function_name = "${var.name_prefix}-redis-secret-rotation"
  role          = aws_iam_role.rotation.arn
  filename      = "${path.module}/placeholder.zip"
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.12"
  timeout       = 30

  environment {
    variables = {
      SECRETS_MANAGER_ENDPOINT = "https://secretsmanager.${var.region}.amazonaws.com"
    }
  }

  vpc_config {
    subnet_ids         = var.subnet_ids
    security_group_ids = var.lambda_sg_ids
  }

  tags = var.tags

  lifecycle {
    ignore_changes = [filename, source_code_hash]
  }
}

resource "aws_secretsmanager_secret_rotation" "redis" {
  count               = var.redis_secret_arn != "" ? 1 : 0
  secret_id           = var.redis_secret_arn
  rotation_lambda_arn = aws_lambda_function.redis_rotation[0].arn

  rotation_rules {
    automatically_after_days = var.rotation_days
  }
}
