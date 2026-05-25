variable "name_prefix"    { type = string }
variable "bucket_name"    { type = string; description = "Globally unique S3 bucket name for CloudTrail logs" }
variable "aws_account_id" { type = string }
variable "tags"           { type = map(string); default = {} }
