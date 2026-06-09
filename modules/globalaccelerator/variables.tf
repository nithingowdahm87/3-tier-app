variable "name_prefix" {
  type = string
}

variable "primary_nlb_arn" {
  type        = string
  description = "ARN of the primary region NLB endpoint"
}

variable "secondary_nlb_arn" {
  type        = string
  description = "ARN of the secondary region NLB endpoint"
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
