terraform {
  required_providers {
    aws = {
      source                = "hashicorp/aws"
      configuration_aliases = [aws.primary, aws.secondary]
    }
  }
}

variable "name_prefix"   { type = string }
variable "sns_topic_arn" { type = string }
variable "tags"          { type = map(string); default = {} }
