variable "name_prefix"        { type = string }
variable "primary_region"     { type = string }
variable "secondary_region"   { type = string }
variable "primary_nlb_arn"    { type = string }
variable "secondary_nlb_arn"  { type = string }
variable "logs_bucket_name"   { type = string }
variable "tags"               { type = map(string); default = {} }
