locals {
  prefix    = "rook-ceph"
}

variable "osd" {
  type = list(object({
    node    = string
    devices = list(string)
  }))
  default = []
}

variable "single_node" {
  type = bool
}