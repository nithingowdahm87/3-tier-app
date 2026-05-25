terraform {
  required_providers {
    aws = { source = "hashicorp/aws" }
  }
}

# Subnet group for Redis
resource "aws_elasticache_subnet_group" "this" {
  name       = "${var.name_prefix}-redis-subnet-group"
  subnet_ids = var.subnet_ids
  tags       = merge(var.tags, { Name = "${var.name_prefix}-redis-subnet-group" })
}

# Security group for Redis — only allow app tier
resource "aws_security_group" "redis" {
  name        = "${var.name_prefix}-redis-sg"
  description = "Redis SG — allow port 6379 from app tier only"
  vpc_id      = var.vpc_id

  ingress {
    from_port       = 6379
    to_port         = 6379
    protocol        = "tcp"
    security_groups = [var.app_sg_id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, { Name = "${var.name_prefix}-redis-sg" })
}

# Auth token stored in Secrets Manager
resource "aws_secretsmanager_secret" "redis_auth" {
  name                    = "/${var.environment}/redis/auth_token"
  recovery_window_in_days = 7
  tags                    = merge(var.tags, { Name = "${var.name_prefix}-redis-auth" })
}

# Redis Replication Group (Multi-AZ, cluster mode disabled for simplicity)
resource "aws_elasticache_replication_group" "this" {
  replication_group_id       = "${var.name_prefix}-redis"
  description                = "MAANG-level Redis: Multi-AZ, encrypted, auth token"
  engine                     = "redis"
  engine_version             = var.redis_version
  node_type                  = var.node_type
  num_cache_clusters         = var.num_cache_nodes
  port                       = 6379
  subnet_group_name          = aws_elasticache_subnet_group.this.name
  security_group_ids         = [aws_security_group.redis.id]
  automatic_failover_enabled = var.num_cache_nodes > 1 ? true : false
  multi_az_enabled           = var.num_cache_nodes > 1 ? true : false
  at_rest_encryption_enabled = true
  transit_encryption_enabled = true
  auth_token                 = var.redis_auth_token
  maintenance_window         = "sun:05:00-sun:06:00"
  snapshot_retention_limit   = 7
  snapshot_window            = "03:00-04:00"
  auto_minor_version_upgrade = true

  log_delivery_configuration {
    destination      = var.cloudwatch_log_group
    destination_type = "cloudwatch-logs"
    log_format       = "json"
    log_type         = "slow-log"
  }

  tags = merge(var.tags, { Name = "${var.name_prefix}-redis" })
}
