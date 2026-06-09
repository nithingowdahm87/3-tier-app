variable "name_prefix" {
  type = string
}

variable "recorder_id" {
  type        = string
  description = "AWS Config recorder ID"
}

variable "config_bucket" {
  type        = string
  description = "S3 bucket used by AWS Config"
}

variable "tags" {
  type    = map(string)
  default = {}
}
