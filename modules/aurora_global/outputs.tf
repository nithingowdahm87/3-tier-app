output "global_cluster_id"        { value = "" }


output "primary_db_instance_id"    { value = aws_db_instance.primary.id }
output "secondary_db_instance_id"  { value = aws_db_instance.secondary.id }
