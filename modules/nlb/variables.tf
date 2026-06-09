variable "name_prefix" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "public_subnet_ids" {
  type = list(string)
}

variable "alb_arn" {
  type        = string
  description = "ARN of the ALB to forward traffic to"
}

variable "tags" {
  type    = map(string)
  default = {}
}
