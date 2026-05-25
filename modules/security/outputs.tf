output "nlb_sg_id" { value = aws_security_group.nlb.id }
output "alb_sg_id" { value = aws_security_group.alb.id }
output "web_sg_id" { value = aws_security_group.web.id }
output "internal_alb_sg_id" { value = aws_security_group.internal_alb.id }
output "app_sg_id" { value = aws_security_group.app.id }
output "aurora_sg_id" { value = aws_security_group.aurora.id }
output "bastion_sg_id" { value = aws_security_group.bastion.id }
