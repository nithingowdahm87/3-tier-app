variable "name_prefix" {
  type = string
}

variable "acm_certificate_arn" {
  type        = string
  description = "ACM cert ARN (must be in us-east-1 for CloudFront)"
}

variable "alb_dns_name" {
  type        = string
  description = "DNS name of the primary ALB used as CloudFront origin"
}

variable "cloudfront_logs_bucket" {
  type        = string
  description = "S3 bucket domain name for CloudFront access logs (e.g. bucket.s3.amazonaws.com)"
}

variable "waf_acl_arn" {
  type        = string
  default     = ""
  description = "ARN of a WAFv2 WebACL scoped to CLOUDFRONT to attach (optional)"
}

variable "tags" {
  type    = map(string)
  default = {}
}
