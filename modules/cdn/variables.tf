variable "name_prefix"        { type = string }
variable "aws_account_id"    { type = string }
variable "acm_certificate_arn" { type = string; default = "" }
variable "waf_web_acl_arn"   { type = string; default = "" }
variable "price_class"       { type = string; default = "PriceClass_100" }
variable "tags"              { type = map(string); default = {} }
