variable "domain_name"               { type = string }
variable "subject_alternative_names" { type = list(string); default = [] }
variable "hosted_zone_id"            { type = string }
variable "nlb_dns_name"              { type = string }
variable "nlb_zone_id"               { type = string }
variable "secondary_nlb_dns_name" {
  type        = string
  description = "DNS name of the secondary region NLB for failover routing"
}
variable "secondary_nlb_zone_id" {
  type        = string
  description = "Zone ID of the secondary region NLB for failover routing"
}
variable "tags" { type = map(string); default = {} }
