variable "keyspaces" {
  type = list(object({
    dbname = string
    username = string
    password = string
  }))
}

output "endpoint" {
  value = {
    url = "mysql://${data.external.vitess_vtgate_services.result.0}.vitess:3306"
  }
}