variable "key_name" {
  type        = string
  description = "Name of the EC2 key pair to create"
}

variable "environment" {
  type        = string
  description = "Environment name used in the Secrets Manager path"
}

variable "tags" { type = map(string); default = {} }
