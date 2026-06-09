variable "name_prefix" {
  type = string
}

variable "acm_certificate_arn" {
  type        = string
  description = "ACM cert ARN (must be in us-east-1 for CloudFront)"
}

variable "alb_dns_name" {
  type        = string
  description = "DNS name of the primary external ALB origin"
}

variable "domain_name" {
  type        = string
  description = "Primary domain name for the CloudFront distribution"
}

variable "tags" {
  type    = map(string)
  default = {}
}
