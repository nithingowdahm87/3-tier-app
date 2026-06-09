variable "name_prefix" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "private_subnet_ids" {
  type = list(string)
}

variable "route_table_ids" {
  type = list(string)
}

variable "app_sg_id" {
  type        = string
  description = "App tier SG - used to scope endpoint ingress"
}

variable "region" {
  type = string
}

variable "tags" {
  type    = map(string)
  default = {}
}
