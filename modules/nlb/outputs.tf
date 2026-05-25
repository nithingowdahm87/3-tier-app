output "nlb_arn" { value = aws_lb.nlb.arn }
output "nlb_dns_name" { value = aws_lb.nlb.dns_name }
output "nlb_zone_id" {
  description = "Hosted zone ID of the NLB — required for Route53 alias records"
  value       = aws_lb.nlb.zone_id
}
