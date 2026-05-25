variable "name_prefix"           { type = string }
variable "alb_arn_suffix"        { type = string }
variable "web_asg_name"          { type = string }
variable "app_asg_name"          { type = string }
variable "aurora_cluster_id"     { type = string }
variable "dynamodb_table_name"   { type = string }
variable "log_archive_bucket_arn" { type = string }
variable "athena_results_bucket" { type = string }
variable "tags"                  { type = map(string); default = {} }
