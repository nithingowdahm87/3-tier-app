output "bastion_asg_name" {
  description = "Name of the bastion Auto Scaling Group"
  value       = aws_autoscaling_group.bastion.name
}
