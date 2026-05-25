output "global_cluster_id" { value = aws_rds_global_cluster.this.id }
output "primary_cluster_endpoint" { value = aws_rds_cluster.primary.endpoint }
output "secondary_cluster_endpoint" { value = aws_rds_cluster.secondary.endpoint }
output "primary_reader_endpoint" { value = aws_rds_cluster.primary.reader_endpoint }
