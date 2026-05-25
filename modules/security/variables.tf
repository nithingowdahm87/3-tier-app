variable "name_prefix" { type = string }
variable "vpc_id" { type = string }
variable "vpc_cidr" {
  type        = string
  description = "VPC CIDR block — used to scope Aurora SG egress to VPC only"
}
variable "bastion_allowed_cidr" {
  type        = string
  description = "CIDR block allowed to SSH to the bastion. Must be explicitly set - no default to prevent accidental 0.0.0.0/0."
}
variable "tags" { type = map(string); default = {} }
