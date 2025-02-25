resource "kubernetes_namespace" "ns" {
  metadata {
    name = "vitess"
  }
}

module "operator" {
  source     = "../utils/apply"
  yaml       = "${path.module}/yaml/operator.yaml"
  depends_on = [kubernetes_namespace.ns]
}

module "vitess" {
  source = "../utils/apply"
  yaml   = "${path.module}/yaml/vitess.yaml"
  args = {
    infos = var.keyspaces
  }
  depends_on = [kubernetes_namespace.ns]
}

resource "null_resource" "wait" {
  provisioner "local-exec" {
    command = "timeout 3000s bash -c 'until kubectl get svc -n vitess 2>/dev/null | grep \"^vitess-vtgate\"; do : ; done'"
  }
  depends_on = [module.vitess]
}

data "external" "vitess_vtgate_services" {
  program = ["bash", "-c", <<EOT
kubectl get svc -n vitess --no-headers -o custom-columns=":metadata.name" | grep "^vitess-vtgate" | jq -R -s -c "split(\"\n\")[:-1] | to_entries | map({(.key|tostring): .value}) | add"
EOT
  ]
  depends_on = [null_resource.wait]
}
