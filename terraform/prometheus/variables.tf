variable "domain" {
  type = string
}

variable "prefix" {
  type = object({
    grafana = string
    gitlab = string
  })
}

variable "password" {
  type = string
}