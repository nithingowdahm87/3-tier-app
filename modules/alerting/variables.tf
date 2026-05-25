variable "name_prefix"          { type = string }
variable "alert_email"          { type = string; default = "" }
variable "alb_arn_suffix"       { type = string }
variable "web_tg_arn_suffix"    { type = string }
variable "aurora_cluster_id"    { type = string }
variable "dynamodb_table_name" { type = string }
variable "asg_names"           { type = list(string) }
variable "alb_5xx_threshold"   { type = number; default = 10 }
variable "aurora_max_connections" { type = number; default = 800 }
variable "min_healthy_hosts"   { type = number; default = 2 }
variable "tags"                { type = map(string); default = {} }
