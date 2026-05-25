terraform {
  required_providers {
    aws = {
      source                = "hashicorp/aws"
      configuration_aliases = [aws.primary, aws.secondary]
    }
  }
}

variable "name_prefix" { type = string }
variable "primary_db_subnet_ids" { type = list(string) }
variable "secondary_db_subnet_ids" { type = list(string) }
variable "primary_aurora_sg_id" { type = string }
variable "secondary_aurora_sg_id" { type = string }
variable "engine" { type = string; default = "aurora-mysql" }
variable "engine_version" { type = string; default = "8.0.mysql_aurora.3.08.0" }
variable "database_name" { type = string; default = "appdb" }
variable "master_username" { type = string; default = "admin" }
variable "master_password" {
  type        = string
  sensitive   = true
  description = "Aurora master password. Should be sourced from Secrets Manager, not set directly."
}
variable "tags" { type = map(string); default = {} }
