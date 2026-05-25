variable "bucket_name" {
  type        = string
  description = "Name of the S3 bucket for ALB access logs"
}

variable "log_retention_days" {
  type        = number
  description = "Number of days to retain ALB access logs before auto-expiry"
  default     = 90
}

variable "force_destroy" {
  type        = bool
  description = "Allow bucket destruction even if it contains objects (set false for prod)"
  default     = false
}

variable "tags" { type = map(string); default = {} }
