variable "name_prefix" {
  type = string
}

variable "subnet_ids" {
  type = list(string)
}

variable "bastion_sg_id" {
  type = string
}

variable "key_name" {
  type = string
}

variable "instance_type" {
  type    = string
  default = "t3.micro"
}

variable "tags" {
  type    = map(string)
  default = {}
}
