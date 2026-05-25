terraform {
  required_providers {
    aws = { source = "hashicorp/aws" }
  }
}

resource "aws_secretsmanager_secret" "this" {
  name                    = var.secret_name
  description             = var.description
  recovery_window_in_days = 7
  tags                    = var.tags
}

# Aurora password rotation Lambda
resource "aws_secretsmanager_secret_rotation" "aurora" {
  count               = var.enable_rotation ? 1 : 0
  secret_id           = aws_secretsmanager_secret.this.id
  rotation_lambda_arn = var.rotation_lambda_arn

  rotation_rules {
    automatically_after_days = var.rotation_days
  }
}
