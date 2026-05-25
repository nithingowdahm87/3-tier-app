output "certificate_arn" {
  description = "Validated ACM certificate ARN — use this as primary_acm_certificate_arn in the ALB module"
  value       = aws_acm_certificate_validation.this.certificate_arn
}

output "domain_name" {
  description = "The primary domain name"
  value       = var.domain_name
}
