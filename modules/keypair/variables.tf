variable "name_prefix" {
  type = string
}

variable "public_key" {
  type        = string
  description = "SSH public key material"
  default     = ""
}

variable "generate" {
  type        = bool
  default     = true
  description = "Set false to use an existing public_key instead of generating one"
}

variable "tags" {
  type    = map(string)
  default = {}
}
