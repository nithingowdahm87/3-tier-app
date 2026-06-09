variable "name_prefix" {
  type = string
}

variable "role" {
  type        = string
  description = "Role label for this ASG tier (e.g. web, app)"
  default     = "app"
}

variable "instance_type" {
  type    = string
  default = "t3.small"
}

variable "min_size" {
  type    = number
  default = 1
}

variable "max_size" {
  type    = number
  default = 4
}

variable "desired_capacity" {
  type    = number
  default = 2
}

variable "subnet_ids" {
  type = list(string)
}

variable "target_group_arns" {
  type    = list(string)
  default = []
}

variable "security_group_ids" {
  type = list(string)
}

variable "key_name" {
  type = string
}

variable "user_data" {
  type    = string
  default = ""
}

variable "iam_instance_profile" {
  type    = string
  default = ""
}

variable "tags" {
  type    = map(string)
  default = {}
}
