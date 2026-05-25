output "accelerator_dns_name" { value = aws_globalaccelerator_accelerator.this.dns_name }
output "accelerator_arn"      { value = aws_globalaccelerator_accelerator.this.id }
output "static_ip_addresses"  { value = aws_globalaccelerator_accelerator.this.ip_sets[*].ip_addresses }
