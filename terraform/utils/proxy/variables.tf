variable "name" {
  type = string
}

variable "destination" {
  type = string
}

variable "namespace" {
  type = string
}

variable "istio" {
  type = bool
}

variable "snippet_location" {
  type    = string
  default = ""
}

variable "snippet_http" {
  type    = string
  default = ""
}

output "labels" {
  value = kubernetes_deployment.proxy_deploy.metadata.0.labels
}
