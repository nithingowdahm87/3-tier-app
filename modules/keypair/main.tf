# EC2 Key Pair Module
# Generates an RSA key pair, registers it with EC2, and stores the
# private key securely in AWS Secrets Manager.
# Retrieve the private key for SSH: 
#   aws secretsmanager get-secret-value --secret-id <secret_name>

resource "tls_private_key" "this" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "this" {
  key_name   = var.key_name
  public_key = tls_private_key.this.public_key_openssh
  tags       = merge(var.tags, { Name = var.key_name })
}

resource "aws_secretsmanager_secret" "private_key" {
  name                    = "/${var.environment}/keypair/${var.key_name}"
  description             = "Private SSH key for EC2 key pair: ${var.key_name}"
  recovery_window_in_days = 7
  tags                    = merge(var.tags, { Name = "${var.key_name}-private-key" })
}

resource "aws_secretsmanager_secret_version" "private_key" {
  secret_id     = aws_secretsmanager_secret.private_key.id
  secret_string = tls_private_key.this.private_key_pem
}
