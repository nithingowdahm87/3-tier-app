terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      configuration_aliases = [ aws.peer ]
    }
  }
}

variable "name_prefix" { type = string }
variable "vpc_id" { type = string }
variable "peer_vpc_id" { type = string }
variable "peer_owner_id" { type = string }
variable "peer_region" { type = string }
variable "requester_route_table_id" { type = string }
variable "peer_route_table_id" { type = string }
variable "requester_cidr" { type = string }
variable "peer_cidr" { type = string }
variable "tags" { type = map(string) default = {} }
