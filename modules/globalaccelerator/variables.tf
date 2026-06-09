variable "name_prefix" {
  type        = string
  description = "Prefix for resource naming"
}

variable "primary_region" {
  type        = string
  description = "Primary AWS region"
}

variable "secondary_region" {
  type        = string
  description = "Secondary AWS region"
}

variable "nlb_primary_arn" {
  type        = string
  description = "ARN of the primary NLB endpoint"
}

variable "nlb_secondary_arn" {
  type        = string
  description = "ARN of the secondary NLB endpoint"
}

variable "tags" {
  type    = map(string)
  default = {}
}
