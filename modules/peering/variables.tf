terraform {
  required_providers {
    aws = {
      source                = "hashicorp/aws"
      configuration_aliases = [aws.peer]
    }
  }
}

variable "name_prefix" { type = string }
variable "vpc_id" { type = string }
variable "peer_vpc_id" { type = string }
variable "peer_owner_id" { type = string }
variable "peer_region" { type = string }

variable "requester_route_table_ids" {
  type        = list(string)
  description = "All private route table IDs in the requester VPC (one per AZ) — peering route added to each"
}

variable "peer_route_table_ids" {
  type        = list(string)
  description = "All private route table IDs in the peer VPC (one per AZ) — peering route added to each"
}

variable "requester_cidr" { type = string }
variable "peer_cidr" { type = string }
variable "tags" { type = map(string); default = {} }
