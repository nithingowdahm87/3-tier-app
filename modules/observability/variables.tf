variable "name_prefix" {
  type = string
}

variable "logs_bucket_name" {
  type        = string
  description = "Globally unique S3 bucket name for centralised log aggregation"
}

variable "alb_arn_suffix" {
  type        = string
  description = "ALB ARN suffix for CloudWatch dashboard metrics"
}

variable "web_asg_name" {
  type = string
}

variable "app_asg_name" {
  type = string
}

variable "aurora_cluster_id" {
  type = string
}

variable "dynamodb_table_name" {
  type = string
}

variable "waf_acl_name" {
  type        = string
  default     = ""
  description = "WAF Web ACL name for the dashboard widget. Leave empty to omit the WAF widget."
}

variable "region" {
  type        = string
  description = "AWS region for WAF metric dimensions"
}

variable "tags" {
  type    = map(string)
  default = {}
}
