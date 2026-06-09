variable "domain_name" {
  type = string
}

variable "subject_alternative_names" {
  type    = list(string)
  default = []
}

variable "zone_id" {
  type        = string
  description = "Route53 hosted zone ID for DNS validation"
}

variable "tags" {
  type    = map(string)
  default = {}
}
