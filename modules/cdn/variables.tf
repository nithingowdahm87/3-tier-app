variable "name_prefix" {
  type        = string
  description = "Prefix for resource naming"
}

variable "alb_dns_name" {
  type        = string
  description = "DNS name of the ALB to use as CloudFront origin"
}

variable "acm_certificate_arn" {
  type        = string
  description = "ACM cert ARN (must be in us-east-1 for CloudFront)"
  default     = ""
}

variable "waf_acl_arn" {
  type        = string
  description = "ARN of WAFv2 WebACL to associate (leave empty to skip)"
  default     = ""
}

variable "cloudfront_logs_bucket" {
  type        = string
  description = "S3 bucket domain name for CloudFront access logs"
  default     = ""
}

variable "tags" {
  type    = map(string)
  default = {}
}
