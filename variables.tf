variable "name" {
  type = string
}
variable "network_cidr_block" {
  type = string
}
variable "availability_zones" {
  type = list(string)
}

variable "allowed_aws_accounts" {
  type    = list(string)
  default = []
}

variable "allowed_cidr_blocks" {
  type    = list(string)
  default = []
}

variable "datadog_api_key_secret_name" {
  type = string
}

variable "otel_workers_count" {
  type    = number
  default = 1
}
