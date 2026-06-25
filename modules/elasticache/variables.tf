variable "name_prefix" {
  type        = string
  description = "Prefix for all ElastiCache resource names"
}

variable "node_type" {
  type    = string
  default = "cache.t4g.small"
}

variable "num_cache_nodes" {
  type        = number
  description = "Number of cache nodes / replicas in the replication group"
  default     = 2
}

variable "redis_sg_id" {
  type        = string
  description = "Security group ID to attach to the ElastiCache replication group"
}

variable "redis_auth_token" {
  type        = string
  description = "AUTH token (password) for Redis in-transit encryption"
  sensitive   = true
}

variable "log_group_name" {
  type        = string
  description = "CloudWatch Log Group name for ElastiCache slow/engine logs"
  default     = ""
}

variable "subnet_ids" {
  type        = list(string)
  description = "List of subnet IDs for the ElastiCache subnet group"
}

variable "kms_key_id" {
  type        = string
  description = "KMS key ID for at-rest encryption"
  default     = ""
}

variable "tags" {
  type    = map(string)
  default = {}
}

variable "environment" {
  type        = string
  description = "Target environment (e.g. dev, prod)"
}
