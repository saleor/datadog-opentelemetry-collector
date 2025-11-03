variable "name" {
  type = string
}
variable "network_cidr_block" {
  type = string
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

variable "datadog_site" {
  type    = string
  default = "datadoghq.com"
}

variable "otel_workers_count" {
  type    = number
  default = 1
}

variable "additional_load_balancers" {
  type = list(object({
    target_group = object({
      arn = string
    })
    protocol = string
  }))
  default = []

  validation {
    condition     = alltrue([for lb in var.additional_load_balancers : contains(["GRPC", "HTTP"], lb.protocol)])
    error_message = <<-ERROR_MESSAGE
      Protocol of traffic accepted by additional load balancer has to be either GRPC or HTTP.
    ERROR_MESSAGE
  }
}
