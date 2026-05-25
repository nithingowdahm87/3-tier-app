variable "name_prefix" { type = string }
variable "role" { type = string }
variable "instance_type" { type = string default = "t2.micro" }
variable "fallback_instance_type" { type = string default = "t3.micro" }
variable "key_name" { type = string }
variable "security_group_ids" { type = list(string) }
variable "subnet_ids" { type = list(string) }
variable "target_group_arns" { type = list(string) default = [] }
variable "on_demand_base_capacity" { type = number default = 1 }
variable "min_size" { type = number default = 1 }
variable "max_size" { type = number default = 4 }
variable "desired_capacity" { type = number default = 2 }
variable "user_data" { type = string }
variable "tags" { type = map(string) default = {} }
