variable "name_prefix"         { type = string }
variable "config_recorder_id"  {
  type        = string
  description = "ID of the aws_config_configuration_recorder resource (ensures recorder exists before rules)"
  default     = ""
}
variable "tags"                { type = map(string); default = {} }
