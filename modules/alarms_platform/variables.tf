variable "name_prefix" {
  type = string
}

variable "sns_topic_arn" {
  type        = string
  description = "SNS topic ARN for all platform alarms"
}

variable "nat_gateway_ids" {
  type        = list(string)
  description = "List of NAT Gateway IDs to alarm on"
  default     = []
}

variable "nat_connection_threshold" {
  type        = number
  default     = 50000
  description = "Active connections per NAT GW alarm threshold"
}

variable "nat_packet_drop_threshold" {
  type        = number
  default     = 100
  description = "Packet drop count per 5 min before alarming"
}

variable "kms_throttle_threshold" {
  type        = number
  default     = 5
  description = "KMS throttled requests per 5 min"
}

variable "secretsmanager_throttle_threshold" {
  type        = number
  default     = 5
  description = "SecretsManager throttled requests per 5 min"
}

variable "health_check_id" {
  type        = string
  default     = ""
  description = "Route53 health check ID to monitor (optional)"
}

variable "acm_expiry_days_threshold" {
  type        = number
  default     = 30
  description = "Alarm when ACM cert has fewer than N days until expiry"
}

variable "rotation_lambda_name" {
  type        = string
  default     = ""
  description = "Name of the secrets rotation Lambda to monitor for errors"
}

variable "tags" {
  type    = map(string)
  default = {}
}
