variable "name_prefix" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "subnet_id" {
  type = string
}

variable "bastion_sg_id" {
  type = string
}

variable "key_name" {
  type = string
}

variable "tags" {
  type    = map(string)
  default = {}
}
