variable "name_prefix"         { type = string }
variable "environment"         { type = string }
variable "vpc_id"              { type = string }
variable "subnet_ids"          { type = list(string) }
variable "app_sg_id"           { type = string }
variable "redis_version"       { type = string; default = "7.1" }
variable "node_type"           { type = string; default = "cache.t4g.medium" }
variable "num_cache_nodes"     { type = number; default = 2 }
variable "redis_auth_token"    { type = string; sensitive = true }
variable "cloudwatch_log_group" { type = string }
variable "tags"                { type = map(string); default = {} }
