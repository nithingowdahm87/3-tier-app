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

variable "fallback_instance_type" {
  type        = string
  description = "Fallback instance type for mixed-instances policy (Spot/OD override)"
  default     = "t3.medium"
}

variable "on_demand_base_capacity" {
  type        = number
  description = "Minimum number of On-Demand instances in the ASG mixed-instances policy"
  default     = 1
}

variable "secret_path_prefix" {
  type        = string
  description = "Secrets Manager path prefix this tier is allowed to read (e.g. prod/app)"
  default     = "prod"
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

variable "ami_id" {
  type        = string
  description = "Explicit AMI ID to use. If set, skips data.aws_ami lookup. Use for LocalStack."
  default     = ""
}

variable "ami_owners" {
  type        = list(string)
  description = "AMI owner account IDs. Override with [\"000000000000\"] for LocalStack."
  default     = ["099720109477"]
}

variable "tags" {
  type    = map(string)
  default = {}
}
