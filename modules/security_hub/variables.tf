variable "name_prefix"     { type = string }
variable "primary_region" { type = string }
variable "sns_topic_arn"  { type = string }
variable "tags"            { type = map(string); default = {} }
