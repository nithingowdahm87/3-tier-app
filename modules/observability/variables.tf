variable "name_prefix"         { type = string }
variable "logs_bucket_name"    { type = string }
variable "alb_arn_suffix"      { type = string }
variable "web_asg_name"        { type = string }
variable "app_asg_name"        { type = string }
variable "aurora_cluster_id"   { type = string }
variable "dynamodb_table_name" { type = string }
variable "region"              { type = string }
variable "tags"                { type = map(string); default = {} }

# Optional: pass WAF Web ACL name to show a Blocked Requests widget on the dashboard.
# Leave empty (default) when WAF is not yet deployed or to break the
# observability -> WAF circular dependency during bootstrapping.
variable "waf_acl_name" {
  type        = string
  default     = ""
  description = "WAF Web ACL name for the CloudWatch dashboard widget. Leave empty to omit the widget."
}
