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

output "global_accelerator_dns" {
  description = "Global Accelerator DNS — use this for lowest-latency global access"
  value       = module.globalaccelerator.accelerator_dns
}

output "global_accelerator_static_ips" {
  description = "Global Accelerator static IP addresses (allowlist in corporate firewalls)"
  value       = module.globalaccelerator.static_ip_addresses
}

output "cloudfront_domain" {
  description = "CloudFront distribution domain for static assets"
  value       = module.cdn.distribution_domain
}

output "app_url" {
  description = "Application URL"
  value       = "https://${var.domain_name}"
}

output "external_alb_dns" {
  description = "External ALB DNS (behind NLB)"
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

output "redis_primary_endpoint" {
  description = "ElastiCache Redis primary endpoint"
  value       = module.elasticache.primary_endpoint
  sensitive   = true
}

output "redis_reader_endpoint" {
  description = "ElastiCache Redis reader endpoint"
  value       = module.elasticache.reader_endpoint
  sensitive   = true
}

output "redis_auth_secret" {
  description = "Secrets Manager secret name for Redis auth token"
  value       = module.elasticache.auth_secret_name
}

output "cloudtrail_bucket" {
  description = "S3 bucket for CloudTrail logs"
  value       = module.cloudtrail.trail_bucket
}

output "cloudtrail_log_group" {
  description = "CloudWatch log group for real-time CloudTrail event streaming"
  value       = module.cloudtrail.log_group_name
}

output "observability_dashboard" {
  description = "CloudWatch Operations Dashboard name"
  value       = module.observability.dashboard_name
}

output "logs_athena_workgroup" {
  description = "Athena workgroup for querying centralised logs"
  value       = module.observability.athena_workgroup
}

output "alerts_sns_topic" {
  description = "SNS topic ARN for all ops alerts"
  value       = module.alerting.sns_topic_arn
}

output "waf_web_acl_arn" {
  description = "WAF Web ACL ARN"
  value       = module.waf.web_acl_arn
}

output "guardduty_primary_detector" {
  description = "GuardDuty detector ID in primary region"
  value       = module.guardduty.primary_detector_id
}

output "fis_terminate_web_template" {
  description = "FIS experiment template ID for web tier EC2 termination chaos"
  value       = module.fis.terminate_web_template_id
}

output "fis_aurora_failover_template" {
  description = "FIS experiment template ID for Aurora failover drill"
  value       = module.fis.aurora_failover_template_id
}

output "primary_flow_log_group" {
  description = "CloudWatch Log Group for primary VPC flow logs"
  value       = module.network_primary.flow_log_group
}

output "secondary_flow_log_group" {
  description = "CloudWatch Log Group for secondary VPC flow logs"
  value       = module.network_secondary.flow_log_group
}
