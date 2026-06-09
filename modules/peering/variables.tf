variable "name_prefix" {
  type = string
}

variable "primary_vpc_id" {
  type = string
}

variable "secondary_vpc_id" {
  type = string
}

variable "primary_vpc_cidr" {
  type = string
}

variable "secondary_vpc_cidr" {
  type = string
}

variable "primary_route_table_ids" {
  type    = list(string)
  default = []
}

variable "secondary_route_table_ids" {
  type    = list(string)
  default = []
}

variable "primary_region" {
  type = string
}

variable "secondary_region" {
  type = string
}

variable "tags" {
  type    = map(string)
  default = {}
}
