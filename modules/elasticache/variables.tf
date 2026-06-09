variable "name_prefix" {
  type        = string
  description = "Name prefix for all ElastiCache resources"
}

variable "environment" {
  type        = string
  description = "Deployment environment (e.g. prod, staging)"
  default     = "prod"
}

variable "node_type" {
  type    = string
  default = "cache.t4g.small"
}

variable "num_cache_nodes" {
  type        = number
  description = "Number of cache nodes in the replication group"
  default     = 2
}

variable "subnet_ids" {
  type        = list(string)
  description = "Subnet IDs for the ElastiCache subnet group"
}

variable "security_group_ids" {
  type        = list(string)
  description = "Security group IDs to attach to the replication group"
}

variable "kms_key_arn" {
  type        = string
  description = "KMS key ARN for ElastiCache at-rest encryption"
  default     = ""
}

variable "tags" {
  type    = map(string)
  default = {}
}
