output "global_cluster_id"        { value = aws_rds_global_cluster.this.id }
output "primary_cluster_endpoint"  { value = aws_rds_cluster.primary.endpoint }
output "secondary_cluster_endpoint" { value = aws_rds_cluster.secondary.endpoint }
output "primary_reader_endpoint"   { value = aws_rds_cluster.primary.reader_endpoint }
output "primary_cluster_arn"       { value = aws_rds_cluster.primary.arn }
output "secondary_cluster_arn"     { value = aws_rds_cluster.secondary.arn }
# Required by module.observability and module.alerting in root main.tf
output "primary_cluster_id"        { value = aws_rds_cluster.primary.cluster_identifier }
output "secondary_cluster_id"      { value = aws_rds_cluster.secondary.cluster_identifier }
