variable "name_prefix"      { type = string }
variable "environment"      { type = string }
variable "subnet_ids"       { type = list(string) }
variable "redis_sg_id"      { type = string }
variable "node_type"        { type = string; default = "cache.t4g.small" }
variable "num_cache_nodes"  { type = number; default = 2 }
variable "redis_auth_token" { type = string; sensitive = true; description = "AUTH token — generate securely and store in Secrets Manager" }
variable "log_group_name"   { type = string; description = "CloudWatch log group name for Redis slow logs" }
variable "tags"             { type = map(string); default = {} }
