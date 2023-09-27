
locals {
  is_linux     = length(regexall("/home/", lower(abspath(path.root)))) > 0
  no_args      = length(keys(var.args)) == 0
  applied_yaml = local.no_args ? var.yaml : var.unique == null ? replace(var.yaml, ".yaml", "_applied.yaml") : replace(var.yaml, ".yaml", "_${var.unique}_applied.yaml")
}

variable "yaml" {
  type = string
}

variable "args" {
  type    = any
  default = {}
}

variable "unique" {
  type    = string
  default = null
}

resource "local_file" "ready" {
  count    = local.no_args ? 0 : 1
  filename = local.applied_yaml
  content  = templatefile(var.yaml, var.args)
}

resource "null_resource" "apply" {
  triggers = {
    yaml = local.applied_yaml
  }
  provisioner "local-exec" {
    when    = create
    command = "kubectl create -f ${self.triggers.yaml}"
  }
  provisioner "local-exec" {
    when    = destroy
    command = "kubectl delete --ignore-not-found=true -f ${self.triggers.yaml}"
  }

  depends_on = [local_file.ready]
}
