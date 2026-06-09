variable "name_prefix" {
  type = string
}

variable "nlb_primary_arn" {
  type        = string
  description = "ARN of the primary region NLB"
}

variable "nlb_secondary_arn" {
  type        = string
  description = "ARN of the secondary region NLB"
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
