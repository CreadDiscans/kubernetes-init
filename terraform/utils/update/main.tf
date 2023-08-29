locals {
  is_linux = length(regexall("/home/", lower(abspath(path.root)))) > 0
}

variable "get" {
  type = string
}

variable "from" {
  type = string
}

variable "to" {
  type = string
}
variable "namespace" {
  type = string
}

resource "null_resource" "update_linux" {
  count = local.is_linux ? 1 : 0
  triggers = {
    get       = var.get
    from      = var.from
    to        = var.to
    namespace = var.namespace
  }
  provisioner "local-exec" {
    command = "${self.triggers.get} | sed -e \"s/${self.triggers.from}/${self.triggers.to}/\" | kubectl apply -f - -n ${self.triggers.namespace}"
  }

  provisioner "local-exec" {
    when    = destroy
    command = "${self.triggers.get} | sed -e \"s/${self.triggers.to}/${self.triggers.from}/\" | kubectl apply -f - -n ${self.triggers.namespace}"
  }
}

resource "null_resource" "update_window" {
  count = local.is_linux ? 0 : 1
  triggers = {
    get       = var.get
    from      = var.from
    to        = var.to
    namespace = var.namespace
  }
  provisioner "local-exec" {
    command     = "${self.triggers.get} | ${"%"}{${"$"}_ -replace \"${self.triggers.from}\", \"${self.triggers.to}\"} | kubectl apply -f - -n ${self.triggers.namespace}"
    interpreter = ["PowerShell", "-Command"]
  }

  provisioner "local-exec" {
    when        = destroy
    command     = "${self.triggers.get} | ${"%"}{${"$"}_ -replace \"${self.triggers.to}\", \"${self.triggers.from}\"} | kubectl apply -f - -n ${self.triggers.namespace}"
    interpreter = ["PowerShell", "-Command"]
  }
}
