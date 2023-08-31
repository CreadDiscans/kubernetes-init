module "setup" {
  source = "../utils/apply"
  yaml   = "${path.module}/yaml/manifests-setup.yaml"
}

resource "time_sleep" "wait" {
  create_duration = "30s"
  depends_on      = [module.setup]
}

module "manifests" {
  source     = "../utils/apply"
  yaml       = "${path.module}/yaml/manifests.yaml"
  depends_on = [time_sleep.wait]
}
