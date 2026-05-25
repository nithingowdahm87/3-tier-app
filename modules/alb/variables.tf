variable "name_prefix" { type = string }
variable "vpc_id" { type = string }
variable "public_subnet_ids" { type = list(string) }
variable "private_subnet_ids" { type = list(string) }
variable "alb_sg_id" { type = string }
variable "internal_alb_sg_id" { type = string }

variable "acm_certificate_arn" {
  type        = string
  description = "ARN of the ACM certificate for HTTPS termination on the external ALB"
}

variable "alb_logs_bucket" {
  type        = string
  description = "S3 bucket name for ALB access logs. The bucket must have the ALB service account bucket policy applied."
}

variable "tags" { type = map(string); default = {} }
