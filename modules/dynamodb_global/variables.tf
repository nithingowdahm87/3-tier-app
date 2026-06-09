variable "name_prefix" {
  type        = string
  description = "Name prefix used to derive the DynamoDB table name"
}

variable "hash_key" {
  type    = string
  default = "id"
}

variable "table_name" {
  type        = string
  description = "Explicit table name (optional; if empty, name_prefix is used)"
  default     = ""
}

variable "range_key" {
  type        = string
  description = "Optional sort key attribute name"
  default     = null
}

variable "kms_key_arn" {
  type        = string
  description = "KMS key ARN for DynamoDB server-side encryption"
  default     = ""
}

variable "replica_regions" {
  type        = list(string)
  description = "List of AWS regions to replicate the table into"
  default     = []
}

variable "replica_region" {
  type        = string
  description = "Single replica region (used by replica block)"
  default     = ""
}

variable "replica_kms_key_arn" {
  type        = string
  description = "KMS key ARN in the replica region"
  default     = ""
}

variable "tags" {
  type    = map(string)
  default = {}
}
