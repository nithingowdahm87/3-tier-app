variable "name_prefix" { type = string }
variable "vpc_id" { type = string }
variable "bastion_allowed_cidr" { type = string default = "0.0.0.0/0" }
variable "tags" { type = map(string) default = {} }
