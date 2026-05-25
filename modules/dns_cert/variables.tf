variable "domain_name" {
  type        = string
  description = "Primary domain name for the ACM certificate and Route53 A record (e.g. app.example.com)"
}

variable "subject_alternative_names" {
  type        = list(string)
  description = "Additional SANs for the certificate (e.g. www.example.com)"
  default     = []
}

variable "hosted_zone_id" {
  type        = string
  description = "Route53 hosted zone ID where validation records and the app A record will be created"
}

variable "nlb_dns_name" {
  type        = string
  description = "DNS name of the NLB (from module.nlb_primary.nlb_dns_name)"
}

variable "nlb_zone_id" {
  type        = string
  description = "Hosted zone ID of the NLB (from module.nlb_primary.nlb_zone_id)"
}

variable "tags" { type = map(string); default = {} }
