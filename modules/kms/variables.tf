variable "name_prefix" {
  type        = string
  description = "Prefix for KMS key aliases — typically project-environment"
}

variable "tags" {
  type    = map(string)
  default = {}
}
