variable "name_prefix" { type = string }
variable "vpc_id"      { type = string }
variable "vpc_cidr"    { type = string; description = "VPC CIDR used to scope Aurora SG egress" }
variable "bastion_allowed_cidr" {
  type        = string
  description = "CIDR block allowed to SSH to the bastion. Must be explicitly set."
}
variable "tags" { type = map(string); default = {} }
