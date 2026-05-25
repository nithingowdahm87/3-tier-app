variable "primary_region" {
  type    = string
  default = "us-east-1"
}

variable "state_bucket_name" {
  type    = string
  default = "my-app-tfstate-prod-2026"
}

variable "lock_table_name" {
  type    = string
  default = "terraform-state-lock"
}
