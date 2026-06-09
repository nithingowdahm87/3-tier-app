variable "name_prefix" {
  type = string
}

variable "subnet_ids" {
  type = list(string)
}

variable "security_group_ids" {
  type = list(string)
}

variable "node_type" {
  type    = string
  default = "cache.t4g.small"
}

variable "num_cache_clusters" {
  type    = number
  default = 2
}

variable "auth_token" {
  type      = string
  sensitive = true
}

variable "tags" {
  type    = map(string)
  default = {}
}
