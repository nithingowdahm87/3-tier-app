variable "name_prefix" {
  type        = string
  description = "Name prefix for NLB resources"
}

variable "subnet_ids" {
  type        = list(string)
  description = "Subnet IDs for the NLB"
}

variable "vpc_id" {
  type        = string
  description = "VPC ID for target group"
}

variable "target_port" {
  type        = number
  description = "Port the NLB target group forwards traffic to"
  default     = 8080
}

variable "tags" {
  type    = map(string)
  default = {}
}
