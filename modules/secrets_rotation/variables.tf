variable "name_prefix"       { type = string }
variable "region"             { type = string }
variable "aurora_secret_arn"  { type = string; default = "" }
variable "redis_secret_arn"   { type = string; default = "" }
variable "kms_key_arn"        { type = string; description = "KMS CMK ARN used to encrypt/decrypt the secrets" }
variable "subnet_ids"         { type = list(string); description = "Private subnets for rotation Lambda VPC config" }
variable "lambda_sg_ids"      { type = list(string); description = "Security groups for the rotation Lambda" }
variable "rotation_days"      { type = number; default = 30; description = "Rotate secrets every N days" }
variable "tags"               { type = map(string); default = {} }
