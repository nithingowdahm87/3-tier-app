variable "name_prefix" {
  type = string
}

variable "recorder_id" {
  type        = string
  description = "AWS Config recorder ID from module.config_rules"
}

variable "recorder_id_secondary" {
  type        = string
  description = "AWS Config recorder ID from module.config_rules_secondary"
}

variable "tags" {
  type    = map(string)
  default = {}
}
