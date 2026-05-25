variable "name_prefix"            { type = string }
variable "environment"            { type = string }
variable "healthy_hosts_alarm_arn" { type = string; description = "CloudWatch alarm ARN used as FIS stop condition" }
variable "aurora_cluster_arn"     { type = string }
variable "tags"                   { type = map(string); default = {} }
