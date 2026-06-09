variable "name_prefix" {
  type = string
}

variable "alert_email" {
  type        = string
  default     = ""
  description = "Email to subscribe to ops alerts SNS topic"
}

variable "alb_arn_suffix" {
  type        = string
  description = "ALB ARN suffix for CloudWatch dimensions"
}

variable "web_target_group_arn_suffix" {
  type        = string
  description = "Web TG ARN suffix"
}

variable "alb_5xx_threshold" {
  type    = number
  default = 10
}

variable "web_min_healthy_hosts" {
  type    = number
  default = 1
}

variable "aurora_cluster_id" {
  type = string
}

variable "aurora_max_connections_threshold" {
  type    = number
  default = 800
}

variable "dynamodb_table_name" {
  type = string
}

variable "web_asg_name" {
  type = string
}

variable "app_asg_name" {
  type = string
}

variable "tags" {
  type    = map(string)
  default = {}
}
