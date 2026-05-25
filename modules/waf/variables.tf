variable "name_prefix" { type = string }
variable "alb_arn" { type = string }
variable "nlb_arn" { type = string }
variable "rate_limit" {
  type        = number
  default     = 2000
  description = "Max requests per 5 minutes per IP before blocking"
}
variable "enable_shield_advanced" {
  type        = bool
  default     = false
  description = "Enable AWS Shield Advanced (requires Shield Advanced subscription, ~$3000/month)"
}
variable "tags" { type = map(string); default = {} }
