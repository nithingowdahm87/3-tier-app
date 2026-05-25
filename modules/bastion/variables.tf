variable "name_prefix" { type = string }

variable "subnet_ids" {
  type        = list(string)
  description = "List of public subnet IDs for the bastion ASG — spans multiple AZs for HA"
}

variable "bastion_sg_id" { type = string }
variable "key_name" { type = string }

variable "instance_type" {
  type        = string
  description = "EC2 instance type for the bastion host"
  default     = "t3.micro"
}

variable "tags" { type = map(string); default = {} }
