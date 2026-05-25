variable "project_name"                    { type = string; default = "myapp" }
variable "primary_region"                  { type = string; default = "us-east-1" }
variable "secondary_region"                { type = string; default = "us-west-2" }
variable "aws_account_id"                  { type = string }
variable "primary_vpc_cidr"                { type = string; default = "10.0.0.0/16" }
variable "secondary_vpc_cidr"              { type = string; default = "10.1.0.0/16" }
variable "domain_name"                     { type = string }
variable "hosted_zone_id"                  { type = string }
variable "bastion_allowed_cidr"            { type = string }
variable "alert_email"                     { type = string; default = "" }
variable "cloudtrail_bucket_name"          { type = string }
variable "config_bucket_name"              { type = string }
variable "logs_bucket_name"                { type = string }
variable "static_assets_bucket_name"       { type = string }
variable "cloudfront_acm_certificate_arn"  { type = string; default = "" }
variable "redis_auth_token"                { type = string; sensitive = true }
variable "alb_5xx_threshold"               { type = number; default = 10 }
variable "aurora_max_connections_threshold" { type = number; default = 800 }
variable "db_name"                         { type = string; default = "appdb" }
variable "db_username"                     { type = string; default = "admin" }
