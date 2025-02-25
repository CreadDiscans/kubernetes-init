
variable "external_ips" {
  type    = string
  default = "x.x.x.x-x.x.x.x"
}

variable "email" {
  type    = string
  default = "user@example.com"
}

variable "osd" {
  type = list(object({
    device        = string
    osdsPerDevice = string
  }))
  default = [
    {
      device        = "/dev/ubuntu-vg/ceph-lv",
      osdsPerDevice = "1"
    }
  ]
}

variable "single_node" {
  type    = bool
  default = true
}

variable "nfs_ip" {
  type    = string
  default = "x.x.x.x"
}

variable "nfs_path" {
  type    = string
  default = "/nfs"
}

variable "domain" {
  type    = string
  default = "example.com"
}

variable "admin" {
  type = object({
    username = string
    password = string
  })
  default = {
    username = "admin"
    password = "admin"
  }
}

# variable "airflow_repo" {
#   type = string
# }
