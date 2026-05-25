output "global_cluster_id" { value = aws_rds_global_cluster.this.id }
output "primary_cluster_endpoint" { value = aws_rds_cluster.primary.endpoint }
output "secondary_cluster_endpoint" { value = aws_rds_cluster.secondary.endpoint }
output "primary_reader_endpoint" { value = aws_rds_cluster.primary.reader_endpoint }
# FIX: expose cluster ARN for use in backup module resource_arns
output "primary_cluster_arn" { value = aws_rds_cluster.primary.arn }
output "secondary_cluster_arn" { value = aws_rds_cluster.secondary.arn }
