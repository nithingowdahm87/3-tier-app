variable "vpc_id" {
  type        = string
  description = "ID of the requester (primary) VPC"
}

variable "peer_vpc_id" {
  type        = string
  description = "ID of the accepter (secondary) VPC"
}

variable "peer_region" {
  type        = string
  description = "AWS region of the accepter VPC (for cross-region peering)"
}

variable "peer_owner_id" {
  type        = string
  description = "AWS account ID of the accepter VPC owner"
  default     = ""
}

variable "primary_cidr" {
  type        = string
  description = "CIDR of the primary VPC — added to secondary route tables"
  default     = ""
}

variable "secondary_cidr" {
  type        = string
  description = "CIDR of the secondary VPC — added to primary route tables"
  default     = ""
}

variable "primary_route_table_ids" {
  type        = list(string)
  description = "Route table IDs in the primary VPC to update with secondary CIDR route"
  default     = []
}

variable "secondary_route_table_ids" {
  type        = list(string)
  description = "Route table IDs in the secondary VPC to update with primary CIDR route"
  default     = []
}

variable "tags" {
  type    = map(string)
  default = {}
}
