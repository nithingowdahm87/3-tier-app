variable "name_prefix" { type = string }
variable "public_subnet_id" { type = string }
variable "bastion_sg_id" { type = string }
variable "key_name" { type = string }
# FIX: instance_type is now a variable (was hardcoded t2.micro)
variable "instance_type" {
  type        = string
  description = "EC2 instance type for the bastion host"
  default     = "t3.micro"
}
variable "tags" { type = map(string) default = {} }
