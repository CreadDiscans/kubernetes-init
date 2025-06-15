variable "ssh_client" {
  type = object({
    user     = string
    ip       = string
    ssh_port = string
    ports    = list(string)
  })
  default = {
    user     = ""
    ip       = ""
    ssh_port = "22"
    ports    = []
  }
}
