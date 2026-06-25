variable "name_prefix" {
  type = string
}

variable "logs_bucket_name" {
  type        = string
  description = "S3 bucket name for Firehose log delivery and Athena results"
}

variable "alb_arn_suffix" {
  type        = string
  description = "ALB ARN suffix for CloudWatch metrics"
}

variable "web_asg_name" {
  type = string
}

variable "app_asg_name" {
  type = string
}

variable "db_instance_id" {
  description = "RDS DB instance identifier for observability"
  type = string
}

variable "dynamodb_table_name" {
  type = string
}

variable "waf_acl_name" {
  type    = string
  default = ""
}

variable "region" {
  type = string
}

variable "tags" {
  type    = map(string)
  default = {}
}
