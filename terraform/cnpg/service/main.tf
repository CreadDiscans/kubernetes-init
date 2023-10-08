variable "name" {
  type = string
}

resource "random_password" "password" {
  length = 16
  special = false
}

resource "kubernetes_secret" "secret" {
  metadata {
    name      = "${var.name}-db-secret"
    namespace = "cnpg-system"
  }
  data = {
    db_name  = var.name
    username = var.name
    password = random_password.password.result
  }
  type = "kubernetes.io/basic-auth"
}

output "info" {
    value = kubernetes_secret.secret.data
}
