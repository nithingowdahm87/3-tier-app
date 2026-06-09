variable "name_prefix" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "vpc_cidr" {
  type = string
}

variable "bastion_allowed_cidr" {
  type        = string
  default     = "10.0.0.0/8"
  description = "CIDR block allowed to SSH to the bastion host"
}

variable "tags" {
  type    = map(string)
  default = {}
}
