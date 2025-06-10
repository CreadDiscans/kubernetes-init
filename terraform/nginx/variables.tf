variable "ssh_client" {
  type = object({
    user  = string
    ip    = string
    ports = list(string)
  })
  default = {
    user  = ""
    ip    = ""
    ports = []
  }
}
