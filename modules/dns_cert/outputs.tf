output "certificate_arn"          { value = aws_acm_certificate_validation.this.certificate_arn }
output "health_check_id"          { value = aws_route53_health_check.primary.id }
output "primary_record_fqdn"      { value = aws_route53_record.app_primary.fqdn }
