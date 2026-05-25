variable "name_prefix"    { type = string }
variable "web_asg_name"  { type = string }
variable "stop_alarm_arn" { type = string; description = "CloudWatch alarm ARN to stop the experiment if things go wrong" }
variable "tags"           { type = map(string); default = {} }
