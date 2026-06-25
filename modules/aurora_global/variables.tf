variable "name_prefix" {
  type = string
}

variable "primary_db_subnet_ids" {
  type = list(string)
}

variable "secondary_db_subnet_ids" {
  type = list(string)
}

variable "primary_aurora_sg_id" {
  type = string
}

variable "secondary_aurora_sg_id" {
  type = string
}

variable "engine" {
  type    = string
  default = "postgres"
}

variable "engine_version" {
  type    = string
  default = "15.9"
}

variable "database_name" {
  type    = string
  default = "appdb"
}

variable "master_username" {
  type    = string
  default = "postgres"
}

variable "master_password" {
  type        = string
  sensitive   = true
  description = "Aurora master password. Should be sourced from Secrets Manager, not set directly."
}

variable "parameter_group_name" {
  type = string
  description = "Parameter group name for the RDS instance"
}
variable "tags" {
  type    = map(string)
  default = {}
}

