variable "name_prefix"          { type = string }
variable "region"               { type = string }
variable "alerts_sns_topic_arn" { type = string }
variable "tags"                 { type = map(string); default = {} }
