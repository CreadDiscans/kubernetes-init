module "config" {
  source   = "../utils/apply"
  yaml     = "${path.module}/yaml/config.yaml"
  args = {
    clients       = var.clients
    domain        = var.domain
  }
}

module "authservice" {
  source     = "../utils/apply"
  yaml       = "${path.module}/yaml/authservice.yaml"
  depends_on = [module.config]
}
