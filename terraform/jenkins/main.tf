resource "kubernetes_namespace" "ns" {
  metadata {
    name = "jenkins"
  }
}

module "oidc" {
  source       = "../utils/oidc"
  keycloak     = var.keycloak
  client_id    = var.prefix
  prefix       = var.prefix
  domain       = var.route.domain
  redirect_uri = ["https://${var.prefix}.${var.route.domain}/securityRealm/finishLogin"]
}

module "jenkins" {
  source = "../utils/apply"
  yaml   = "${path.module}/yaml/jenkins.yaml"
  args = {
    prefix                = var.prefix
    domain                = var.route.domain
    securityRealm         = <<EOF
oic:
          allowedTokenExpirationClockSkewSeconds: 0
          clientId: "${module.oidc.auth.client_id}"
          clientSecret: "${module.oidc.auth.client_secret}"
          disableSslVerification: false
          escapeHatchSecret: "escapeHatchSecret"
          fullNameFieldName: "preferred_username"
          groupIdStrategy: "caseSensitive"
          groupsFieldName: "groups"
          logoutFromOpenidProvider: false
          serverConfiguration:
            wellKnown:
              scopesOverride: "openid"
              wellKnownOpenIDConfigurationUrl: "${module.oidc.wellKnown}"
          userIdStrategy: "caseSensitive"
          userNameField: "preferred_username"
EOF
    authorizationStrategy = <<EOF
roleBased:
          roles:
            global:
            - entries:
              - group: "/jenkins"
              name: "admin"
              pattern: ".*"
              permissions:
              - "Overall/Administer"    
EOF

  }
  depends_on = [kubernetes_namespace.ns]
}

module "service" {
  source    = "../utils/service"
  route     = var.route
  prefix    = var.prefix
  namespace = kubernetes_namespace.ns.metadata.0.name
  port      = 8080
  selector = {
    "app.kubernetes.io/component" : "jenkins-controller"
    "app.kubernetes.io/instance" : "jenkins"
  }
  annotations = {
    "sysflow/favicon" = "/static/26217b19/favicon.ico"
    "sysflow/doc"     = "https://www.jenkins.io/doc/book/getting-started/"
  }
  depends_on = [module.jenkins]
}
