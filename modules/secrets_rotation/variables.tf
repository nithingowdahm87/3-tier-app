variable "name_prefix"         { type = string }
variable "secret_arn"          { type = string; description = "ARN of the Secrets Manager secret to rotate" }
variable "aurora_endpoint"     { type = string; description = "Aurora cluster write endpoint (passed to Lambda via env var)" }
variable "subnet_ids"          { type = list(string); description = "Private subnets for the Lambda VPC config (must have connectivity to Aurora)" }
variable "security_group_ids"  { type = list(string); description = "Security group(s) for the rotation Lambda" }
variable "tags"                { type = map(string); default = {} }
