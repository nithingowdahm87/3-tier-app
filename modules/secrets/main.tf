# Secrets Manager Secret Module
# Creates the secret resource in AWS Secrets Manager.
# The actual secret VALUE is seeded separately (CLI or first-run script)
# to keep it out of Terraform state.
#
# Seed the value after first apply:
#   aws secretsmanager put-secret-value \
#     --secret-id <secret_name> \
#     --secret-string '{"password": "YourStrongPassword123!"}'

resource "aws_secretsmanager_secret" "this" {
  name                    = var.secret_name
  description             = var.description
  recovery_window_in_days = var.recovery_window_in_days
  tags                    = merge(var.tags, { Name = var.secret_name })
}

# Optional automatic rotation using a Lambda (disabled by default)
# Enable by setting var.enable_rotation = true and providing a rotation_lambda_arn
resource "aws_secretsmanager_secret_rotation" "this" {
  count               = var.enable_rotation ? 1 : 0
  secret_id           = aws_secretsmanager_secret.this.id
  rotation_lambda_arn = var.rotation_lambda_arn

  rotation_rules {
    automatically_after_days = var.rotation_days
  }
}
