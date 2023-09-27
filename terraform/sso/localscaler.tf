module "config" {
  # for_each = { for n in var.clients : n.client_id => n if n.client_id == "localscaler" }
  source   = "../utils/apply"
  yaml     = "${path.module}/yaml/config.yaml"
  args = {
    clients       = toset([for each in var.clients : each if each.client_id == "localscaler"])
    domain        = var.domain
  }
}

module "authservice" {
  source     = "../utils/apply"
  yaml       = "${path.module}/yaml/authservice.yaml"
  depends_on = [module.config]
}
