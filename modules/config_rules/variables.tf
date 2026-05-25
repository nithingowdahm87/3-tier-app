variable "name_prefix"     { type = string }
variable "aws_account_id" { type = string }
variable "sns_topic_arn"  { type = string }
variable "tags"            { type = map(string); default = {} }
