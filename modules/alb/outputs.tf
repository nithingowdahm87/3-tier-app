output "external_alb_arn" { value = aws_lb.external.arn }
output "external_alb_dns" { value = aws_lb.external.dns_name }
output "internal_alb_dns" { value = aws_lb.internal.dns_name }
output "web_target_group_arn" { value = aws_lb_target_group.web.arn }
output "app_target_group_arn" { value = aws_lb_target_group.app.arn }
