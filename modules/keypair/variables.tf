variable "name_prefix" {
  type        = string
  description = "Prefix used to derive key_name and Secrets Manager path"
}

variable "public_key" {
  type        = string
  description = "SSH public key material"
  default     = ""
}

variable "generate" {
  type        = bool
  default     = true
  description = "Set false to use an existing public_key instead of generating one"
}

variable "environment" {
  type        = string
  description = "Deployment environment (e.g. prod, staging)"
  default     = ""
}

variable "tags" {
  type    = map(string)
  default = {}
}

locals {
  key_name = var.name_prefix
  env      = var.environment != "" ? var.environment : split("-", var.name_prefix)[length(split("-", var.name_prefix)) - 1]
}
