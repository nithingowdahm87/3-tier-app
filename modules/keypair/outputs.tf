output "key_name" {
  description = "Name of the created EC2 key pair"
  value       = aws_key_pair.this.key_name
}

output "secret_arn" {
  description = "ARN of the Secrets Manager secret storing the private key"
  value       = aws_secretsmanager_secret.private_key.arn
}
