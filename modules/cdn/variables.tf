variable "name_prefix"            { type = string }
variable "bucket_name"            { type = string }
variable "domain_name"            { type = string }
variable "acm_certificate_arn"    { type = string; description = "ACM cert ARN (must be in us-east-1 for CloudFront)" }
variable "waf_web_acl_arn"        { type = string; description = "WAF Web ACL ARN to attach to CloudFront distribution" }
variable "cloudfront_logs_bucket" { type = string; description = "S3 bucket domain for CloudFront access logs" }
variable "tags"                   { type = map(string); default = {} }
