output "primary_vpc_id" {
  description = "Primary VPC ID"
  value       = module.network_primary.vpc_id
}

output "secondary_vpc_id" {
  description = "Secondary VPC ID"
  value       = module.network_secondary.vpc_id
}

output "external_alb_dns" {
  description = "DNS name of the external Application Load Balancer"
  value       = module.alb_primary.external_alb_dns
}

output "nlb_dns_name" {
  description = "DNS name of the Network Load Balancer"
  value       = module.nlb_primary.nlb_dns_name
}

output "bastion_public_ip" {
  description = "Public IP of the bastion host"
  value       = module.bastion_primary.bastion_public_ip
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
