output "key_name" {
  description = "EC2 key pair name — pass this to compute and bastion modules"
  value       = aws_key_pair.this.key_name
}

output "private_key_secret_name" {
  description = "Secrets Manager secret name where the private key PEM is stored"
  value       = aws_secretsmanager_secret.private_key.name
}
