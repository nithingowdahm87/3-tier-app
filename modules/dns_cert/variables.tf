variable "name_prefix" {
  type        = string
  description = "Prefix for resource names and health check tags"
}

variable "domain_name" {
  type        = string
  description = "Primary domain name for ACM cert and Route53 records (e.g. app.example.com)"
}

variable "subject_alternative_names" {
  type    = list(string)
  default = []
}

variable "hosted_zone_id" {
  type        = string
  description = "Route53 hosted zone ID"
}

variable "nlb_dns_name" {
  type        = string
  description = "DNS name of the primary NLB"
}

variable "nlb_zone_id" {
  type        = string
  description = "Hosted zone ID of the primary NLB"
}

variable "secondary_nlb_dns_name" {
  type        = string
  description = "DNS name of the secondary NLB (for failover record)"
  default     = ""
}

variable "secondary_nlb_zone_id" {
  type        = string
  description = "Hosted zone ID of the secondary NLB"
  default     = ""
}

variable "tags" { type = map(string); default = {} }
