variable "domain_name" {
  type        = string
  description = "Primary domain name for the ACM certificate"
}

variable "subject_alternative_names" {
  type    = list(string)
  default = []
}

variable "zone_id" {
  type        = string
  description = "Route 53 hosted zone ID used for DNS validation and A-record creation"
}

variable "nlb_dns_name" {
  type        = string
  description = "DNS name of the primary NLB for Route 53 health check and alias record"
  default     = ""
}

variable "nlb_zone_id" {
  type        = string
  description = "Route 53 hosted zone ID of the primary NLB"
  default     = ""
}

variable "secondary_nlb_dns_name" {
  type        = string
  description = "DNS name of the secondary-region NLB for alias record"
  default     = ""
}

variable "secondary_nlb_zone_id" {
  type        = string
  description = "Route 53 hosted zone ID of the secondary-region NLB"
  default     = ""
}

variable "tags" {
  type    = map(string)
  default = {}
}
