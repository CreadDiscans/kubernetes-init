variable "route" {
  type = object({
    domain = string
    issuer = string
  })
}

variable "prefix" {
  type = string
}

variable "namespace" {
  type = string
}

variable "port" {
  type = any
}

variable "selector" {
  type = any
}

variable "gateway" {
  type    = string
  default = ""
}

variable "annotations" {
  type    = map(string)
  default = {}
}

output "internal_url" {
  value = "http://${var.prefix}-service.${var.namespace}"
}
