variable "name_prefix" {
  type = string
}

variable "alb_arn" {
  type        = string
  description = "ARN of the external ALB to associate WAF with"
}

variable "nlb_arn" {
  type        = string
  description = "ARN of the NLB for Shield Advanced protection"
}

variable "waf_log_destination_arn" {
  type        = string
  description = "ARN of the Kinesis Firehose delivery stream for WAF logging"
}

variable "tags" {
  type    = map(string)
  default = {}
}
