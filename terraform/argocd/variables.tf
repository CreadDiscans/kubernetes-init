variable "domain" {
  type = string
}

variable "prefix" {
  type = object({
    argocd = string
    gitlab = string
  })
}

variable "password" {
  type = string
}
