variable "name_prefix" {
  type = string
}

variable "recorder_id" {
  type        = string
  description = "AWS Config recorder ID"
  default     = ""
}

variable "config_recorder_id" {
  type        = string
  description = "AWS Config recorder status resource ID (accepted for ordering hints, not used in depends_on)"
  default     = ""
}

variable "config_bucket" {
  type        = string
  description = "S3 bucket used by AWS Config"
}

variable "tags" {
  type    = map(string)
  default = {}
}
