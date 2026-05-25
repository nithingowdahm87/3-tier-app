terraform {
  required_providers {
    aws = { source = "hashicorp/aws" }
  }
}

# Auth token stored in Secrets Manager
resource "aws_secretsmanager_secret" "redis_auth" {
  name                    = "/${var.environment}/redis/auth_token"
  description             = "Redis AUTH token for ElastiCache cluster"
  recovery_window_in_days = 7
  tags                    = var.tags
}

resource "aws_elasticache_subnet_group" "this" {
  name       = "${var.name_prefix}-redis-subnet-group"
  subnet_ids = var.subnet_ids
  tags       = var.tags
}

resource "aws_elasticache_replication_group" "this" {
  replication_group_id       = "${var.name_prefix}-redis"
  description                = "Redis cluster for ${var.name_prefix} — session cache, rate limiting, pub/sub"
  node_type                  = var.node_type
  num_cache_clusters         = var.num_cache_nodes
  port                       = 6379
  subnet_group_name          = aws_elasticache_subnet_group.this.name
  security_group_ids         = [var.redis_sg_id]
  parameter_group_name       = "default.redis7"
  engine_version             = "7.0"
  at_rest_encryption_enabled = true
  transit_encryption_enabled = true
  auth_token                 = var.redis_auth_token
  automatic_failover_enabled = var.num_cache_nodes > 1 ? true : false
  multi_az_enabled           = var.num_cache_nodes > 1 ? true : false
  auto_minor_version_upgrade = true
  snapshot_retention_limit   = 7
  snapshot_window            = "03:00-05:00"

  log_delivery_configuration {
    destination      = var.log_group_name
    destination_type = "cloudwatch-logs"
    log_format       = "json"
    log_type         = "slow-log"
  }

  tags = merge(var.tags, { Name = "${var.name_prefix}-redis" })
}
