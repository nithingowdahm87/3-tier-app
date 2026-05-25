output "primary_vpc_id" {
  description = "Primary VPC ID"
  value       = module.network_primary.vpc_id
}

output "secondary_vpc_id" {
  description = "Secondary VPC ID"
  value       = module.network_secondary.vpc_id
}

output "nlb_dns_name" {
  description = "DNS name of the NLB — point your Route53 record or domain here (not the ALB directly)"
  value       = module.nlb_primary.nlb_dns_name
}

output "external_alb_dns" {
  description = "DNS name of the external ALB (behind the NLB — for internal reference only)"
  value       = module.alb_primary.external_alb_dns
}

output "bastion_asg_name" {
  description = "Bastion Auto Scaling Group name. Use 'aws ec2 describe-instances --filters Name=tag:aws:autoscaling:groupName,Values=<asg_name>' to find the current bastion IP."
  value       = module.bastion_primary.bastion_asg_name
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
