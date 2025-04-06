locals {
  prefix    = "rook-ceph"
}

variable "osd" {
  type = list(object({
    device        = string
    osdsPerDevice = string
  }))
}

variable "single_node" {
  type = bool
}