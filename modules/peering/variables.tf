variable "name_prefix" {
  type        = string
  description = "Name prefix for VPC peering resources"
}

variable "primary_vpc_id" {
  type        = string
  description = "VPC ID of the primary (requester) VPC"
}

variable "secondary_vpc_id" {
  type        = string
  description = "VPC ID of the secondary (accepter) VPC"
}

variable "primary_region" {
  type        = string
  description = "AWS region of the primary VPC"
}

variable "secondary_region" {
  type        = string
  description = "AWS region of the secondary VPC"
}

variable "primary_route_table_ids" {
  type        = list(string)
  description = "Route table IDs in the primary VPC to add peering routes"
  default     = []
}

variable "secondary_route_table_ids" {
  type        = list(string)
  description = "Route table IDs in the secondary VPC to add peering routes"
  default     = []
}

variable "primary_cidr" {
  type        = string
  description = "CIDR block of the primary VPC"
}

variable "secondary_cidr" {
  type        = string
  description = "CIDR block of the secondary VPC"
}

variable "tags" {
  type    = map(string)
  default = {}
}
