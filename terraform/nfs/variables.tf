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
