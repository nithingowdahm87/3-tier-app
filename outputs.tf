output "primary_vpc_id" {
  description = "Primary VPC ID"
  value       = module.network_primary.vpc_id
}

output "secondary_vpc_id" {
  description = "Secondary VPC ID"
  value       = module.network_secondary.vpc_id
}

output "nlb_dns_name" {
  description = "NLB DNS name — your Route53 A record aliases to this"
  value       = module.nlb_primary.nlb_dns_name
}

output "app_url" {
  description = "Application URL"
  value       = "https://${var.domain_name}"
}

output "external_alb_dns" {
  description = "External ALB DNS (behind NLB — for internal reference)"
  value       = module.alb_primary.external_alb_dns
}

output "bastion_asg_name" {
  description = "Bastion ASG name. Find current IP: aws ec2 describe-instances --filters Name=tag:aws:autoscaling:groupName,Values=<name>"
  value       = module.bastion_primary.bastion_asg_name
}

output "bastion_ssh_key_secret" {
  description = "Secrets Manager secret name where the bastion private key PEM is stored"
  value       = module.keypair.private_key_secret_name
}

output "alb_logs_bucket" {
  description = "S3 bucket name for ALB access logs"
  value       = module.logging.bucket_name
}

output "aurora_password_secret" {
  description = "Secrets Manager secret name for Aurora master password"
  value       = module.aurora_secret.secret_name
}

output "aurora_primary_endpoint" {
  description = "Aurora primary cluster write endpoint"
  value       = module.aurora.primary_cluster_endpoint
  sensitive   = true
}

output "aurora_primary_reader_endpoint" {
  description = "Aurora primary cluster read endpoint"
  value       = module.aurora.primary_reader_endpoint
  sensitive   = true
}

output "aurora_secondary_endpoint" {
  description = "Aurora secondary cluster endpoint (DR region)"
  value       = module.aurora.secondary_cluster_endpoint
  sensitive   = true
}

output "primary_flow_log_group" {
  description = "CloudWatch Log Group for primary VPC flow logs"
  value       = module.network_primary.flow_log_group
}

output "secondary_flow_log_group" {
  description = "CloudWatch Log Group for secondary VPC flow logs"
  value       = module.network_secondary.flow_log_group
}
