variable "name_prefix"           { type = string }
variable "alerts_sns_topic_arn"  { type = string; description = "SNS topic ARN for GuardDuty HIGH/CRITICAL finding alerts" }
variable "tags"                  { type = map(string); default = {} }
