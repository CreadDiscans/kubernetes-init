resource "tls_private_key" "ssh_key_pair" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "kubernetes_secret" "ssh_key_secret" {
  metadata {
    name      = "ssh-key-secret"
    namespace = kubernetes_namespace.ns.metadata.0.name
  }
  type = "Opaque"
  data = {
    "id_rsa"     = tls_private_key.ssh_key_pair.private_key_pem
    "id_rsa.pub" = tls_private_key.ssh_key_pair.public_key_openssh
  }
}

resource "local_file" "ssh_key" {
  filename = "test.pem"
  content  = tls_private_key.ssh_key_pair.private_key_pem
}

resource "kubernetes_deployment" "ssh_remote_forward" {
  for_each = toset(var.ssh_client.ports)
  metadata {
    name      = "ssh-forward-${each.value}"
    namespace = kubernetes_namespace.ns.metadata.0.name
  }
  spec {
    replicas = 1
    selector {
      match_labels = {
        app = "ssh-${each.value}"
      }
    }
    template {
      metadata {
        labels = {
          app = "ssh-${each.value}"
        }
      }
      spec {
        container {
          name    = "ssh"
          image   = "rastasheep/ubuntu-sshd:latest"
          command = ["bash", "-c"]
          args    = ["ssh -o StrictHostKeyChecking=no -o ExitOnForwardFailure=yes ${var.ssh_client.user}@${var.ssh_client.ip} -R ${each.value}:ingress-nginx-controller:${each.value} -N -vvv"]
          volume_mount {
            name       = "ssh-key"
            mount_path = "/root/.ssh/id_rsa"
            sub_path   = "id_rsa"
            read_only  = true
          }
          volume_mount {
            name       = "ssh-key"
            mount_path = "/root/.ssh/id_rsa.pub"
            sub_path   = "id_rsa.pub"
            read_only  = true
          }
        }
        volume {
          name = "ssh-key"
          secret {
            secret_name  = kubernetes_secret.ssh_key_secret.metadata.0.name
            default_mode = "0600"
          }
        }
      }
    }
  }
}
