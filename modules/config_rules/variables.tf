variable "name_prefix"    { type = string }
variable "bucket_name"    { type = string }
variable "aws_account_id" { type = string }
variable "tags"           { type = map(string); default = {} }
