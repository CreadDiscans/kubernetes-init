resource "kubernetes_namespace" "ns" {
  metadata {
    name = "rook-ceph"
  }
}

module "snapshot_crd" {
  source     = "../../utils/apply"
  yaml       = "${path.module}/yaml/snapshot"
  depends_on = [kubernetes_namespace.ns]
}

module "crds" {
  source     = "../../utils/apply"
  yaml       = "${path.module}/yaml/crds.yaml"
  depends_on = [kubernetes_namespace.ns]
}

module "common" {
  source     = "../../utils/apply"
  yaml       = "${path.module}/yaml/common.yaml"
  depends_on = [module.crds]
}

module "operator" {
  source     = "../../utils/apply"
  yaml       = "${path.module}/yaml/operator.yaml"
  depends_on = [module.common]
}

module "cluster" {
  source = "../../utils/apply"
  yaml   = "${path.module}/yaml/cluster.yaml"
  args = {
    devices              = var.osd
    allowMultiplePerNode = var.single_node ? true : false
  }
  depends_on = [module.operator]
}

resource "null_resource" "wait" {
  provisioner "local-exec" {
    command = "timeout 3000s bash -c 'until kubectl get svc/rook-ceph-mgr-dashboard -n rook-ceph --output=jsonpath='{.metadata.name}' 2>/dev/null | grep \"rook-ceph-mgr-dashboard\"; do : ; done'"
  }
  depends_on = [module.cluster]
}

module "toolbox" {
  source     = "../../utils/apply"
  yaml       = "${path.module}/yaml/toolbox.yaml"
  depends_on = [null_resource.wait]
}

module "service" {
  source    = "../../utils/service"
  namespace = kubernetes_namespace.ns.metadata.0.name
  prefix    = local.prefix
  domain    = var.domain
  port      = 7000
  selector = {
    app          = "rook-ceph-mgr"
    mgr_role     = "active"
    rook_cluster = "rook-ceph"
  }
  annotations = {
    "sysflow/favicon" = "/favicon.ico"
    "sysflow/doc"     = "https://rook.io/docs/rook/latest-release/Getting-Started/intro/"
  }
}
