variable "name_prefix" {
  type        = string
  description = "Name prefix for NLB resources"
}

variable "vpc_id" {
  type        = string
  description = "VPC ID for target group"
}

variable "public_subnet_ids" {
  type        = list(string)
  description = "Public subnet IDs for the NLB"
}

variable "alb_arn" {
  type        = string
  description = "ARN of the ALB to forward traffic from NLB to"
}

variable "tags" {
  type    = map(string)
  default = {}
}
