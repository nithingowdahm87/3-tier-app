variable "table_name" { type = string }
variable "hash_key" { type = string default = "id" }
variable "range_key" { type = string default = null }
variable "replica_region" { type = string }
variable "tags" { type = map(string) default = {} }
