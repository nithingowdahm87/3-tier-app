output "primary_endpoint"       { value = aws_elasticache_replication_group.this.primary_endpoint_address }
output "reader_endpoint"        { value = aws_elasticache_replication_group.this.reader_endpoint_address }
output "port"                   { value = 6379 }
output "auth_secret_name"       { value = aws_secretsmanager_secret.redis_auth.name }
