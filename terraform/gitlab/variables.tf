variable "prefix" {
  type = object({
    gitlab = string
    registry = string
  })
}

variable "domain" {
  type = string
}

variable "password" {
  type = string
}
