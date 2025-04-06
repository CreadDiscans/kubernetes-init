
variable "external_ips" {
  type    = string
  default = "x.x.x.x-x.x.x.x"
}

variable "route" {
  type = object({
    domain = string
    issuer = string
    email  = string
  })
  default = {
    domain = "example.com"
    issuer = "letsencrypt-staging"
    email  = "user@example.com"
  }
}

variable "aws_key" {
  type = object({
    aws_access_key_id     = string
    aws_secret_access_key = string
  })
  default = {
    aws_access_key_id     = ""
    aws_secret_access_key = ""
  }
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

variable "nfs_info" {
  type = object({
    ip   = string
    path = string
  })
  default = {
    ip   = "x.x.x.x"
    path = "/nfs"
  }
}

variable "airflow_repo" {
  type    = string
  default = "/system/airflow.git"
}
