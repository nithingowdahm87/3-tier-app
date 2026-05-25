output "secret_name" {
  description = "The secret name/path in AWS Secrets Manager"
  value       = aws_secretsmanager_secret.this.name
}

output "secret_arn" {
  description = "The secret ARN"
  value       = aws_secretsmanager_secret.this.arn
}
