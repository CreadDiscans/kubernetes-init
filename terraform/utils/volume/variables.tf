variable "name" {
  type = string
}

variable "namespace" {
  type = string
}

output "pvc_name" {
    value = kubernetes_persistent_volume_claim.pvc.metadata.0.name
}