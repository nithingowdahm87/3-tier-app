output "vpc_id" {
  value = aws_vpc.this.id
}

output "public_subnet_ids" {
  value = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  value = aws_subnet.private[*].id
}

output "db_subnet_ids" {
  value = aws_subnet.db[*].id
}

output "private_route_table_ids" {
  value = aws_route_table.private[*].id
}

output "private_route_table_id" {
  value = aws_route_table.private[0].id
}

output "public_route_table_id" {
  value = aws_route_table.public.id
}

output "db_route_table_id" {
  value = aws_route_table.db[0].id
}

output "flow_log_group" {
  value = aws_cloudwatch_log_group.flow_log.name
}

output "nat_gateway_ids" {
  description = "List of NAT Gateway IDs (one per AZ)"
  value       = aws_nat_gateway.this[*].id
}
