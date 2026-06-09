variable "secret_name" {
  type = string
}

variable "description" {
  type    = string
  default = ""
}

variable "enable_rotation" {
  type        = bool
  default     = false
  description = "Set true and provide rotation_lambda_arn to enable automatic rotation"
}

variable "rotation_lambda_arn" {
  type        = string
  default     = ""
  description = "ARN of the rotation Lambda. See: https://docs.aws.amazon.com/secretsmanager/latest/userguide/rotating-secrets.html"
}

variable "rotation_days" {
  type    = number
  default = 30
}

variable "tags" {
  type    = map(string)
  default = {}
}
