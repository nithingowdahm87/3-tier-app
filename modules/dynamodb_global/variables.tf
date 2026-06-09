variable "name_prefix" {
  type = string
}

variable "hash_key" {
  type    = string
  default = "id"
}

variable "replica_regions" {
  type        = list(string)
  default     = []
  description = "Additional regions to replicate the DynamoDB table to"
}

variable "tags" {
  type    = map(string)
  default = {}
}
