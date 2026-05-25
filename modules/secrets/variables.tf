variable "secret_name" {
  type        = string
  description = "Name/path of the secret in AWS Secrets Manager (e.g. /prod/aurora/master_password)"
}

variable "description" {
  type        = string
  description = "Human-readable description of the secret"
  default     = ""
}

variable "recovery_window_in_days" {
  type        = number
  description = "Days before a deleted secret is permanently removed (0 = immediate)"
  default     = 7
}

variable "enable_rotation" {
  type        = bool
  description = "Enable automatic secret rotation via Lambda"
  default     = false
}

variable "rotation_lambda_arn" {
  type        = string
  description = "ARN of the Lambda function for secret rotation (required if enable_rotation = true)"
  default     = ""
}

variable "rotation_days" {
  type        = number
  description = "Rotate the secret every N days"
  default     = 30
}

variable "tags" { type = map(string); default = {} }
