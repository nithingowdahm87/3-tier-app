output "vpc_id" { value = aws_vpc.this.id }
output "public_subnet_ids" { value = aws_subnet.public[*].id }
output "private_subnet_ids" { value = aws_subnet.private[*].id }
output "db_subnet_ids" { value = aws_subnet.db[*].id }
# FIX: Now returns a list (one per AZ) instead of a single route table
output "private_route_table_ids" { value = aws_route_table.private[*].id }
output "private_route_table_id" { value = aws_route_table.private[0].id }
output "public_route_table_id" { value = aws_route_table.public.id }
output "db_route_table_id" { value = aws_route_table.db[0].id }
