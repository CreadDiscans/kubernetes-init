resource "kubernetes_service_account" "runner_sa" {
  metadata {
    name      = "runner-sa"
    namespace = kubernetes_namespace.ns.metadata.0.name
  }
}

resource "kubernetes_role" "runner_role" {
  metadata {
    name      = "runner-role"
    namespace = kubernetes_namespace.ns.metadata.0.name
  }
  rule {
    api_groups = ["extensions", "apps"]
    resources  = ["deployments"]
    verbs      = ["get", "list", "watch", "create", "update", "patch", "delete"]
  }
  rule {
    api_groups = [""]
    resources  = ["pods", "services", "secrets", "pods/exec", "serviceaccounts", "pods/attach"]
    verbs      = ["get", "list", "watch", "create", "update", "patch", "delete"]
  }
}

resource "kubernetes_role_binding" "runner_role_binding" {
  metadata {
    name      = "runner-rb"
    namespace = kubernetes_namespace.ns.metadata.0.name
  }
  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account.runner_sa.metadata.0.name
    namespace = kubernetes_namespace.ns.metadata.0.name
  }
  role_ref {
    kind      = "Role"
    name      = kubernetes_role.runner_role.metadata.0.name
    api_group = "rbac.authorization.k8s.io"
  }
}

resource "kubernetes_config_map" "runner_config" {
  metadata {
    name      = "runner-config"
    namespace = kubernetes_namespace.ns.metadata.0.name
  }
  data = {
    "config.toml" = <<EOF
        concurrent = 4
        [[runners]]
        tls-ca-file = "/etc/gitlab-runner/certs/tls.crt"
        name = "kubernetes-runner"
        url = "${module.service.internal_url}"
        token = "$TOKEN"
        executor = "kubernetes"
        [runners.kubernetes]
            namespace = "${kubernetes_namespace.ns.metadata.0.name}"
            image = "docker:latest"
            privileged = true
            cpu_request = "1"
            cpu_limit = "1"
            memory_request = "4Gi"
            memory_limit = "4Gi"
            [[runners.kubernetes.volumes.host_path]]
              name = "docker"
              mount_path = "/var/run/docker.sock"
              host_path = "/var/run/docker.sock"
        EOF
  }
}

resource "kubernetes_persistent_volume_claim" "pvc" {
  metadata {
    name      = "runner-pvc"
    namespace = kubernetes_namespace.ns.metadata.0.name
  }
  spec {
    access_modes = ["ReadWriteOnce"]
    resources {
      requests = {
        storage = "1Gi"
      }
    }
  }
}

resource "kubernetes_config_map" "runner_script" {
  metadata {
    name = "runner-scipt"
    namespace = kubernetes_namespace.ns.metadata.0.name
  }
  data = {
    "script.py" = <<EOF
from selenium import webdriver
from selenium.webdriver.common.by import By
from selenium.webdriver.chrome.service import Service
from webdriver_manager.chrome import ChromeDriverManager
import time
import os

host = "https://${var.prefix.gitlab}.${var.route.domain}"
username = "root"
password = "${local.password}"
source = "/etc/gitlab-runner/config.toml"
destination = "/etc/gitlab-runner-getter/config.toml"

def get_token():
    print('start get_token')
    options = webdriver.ChromeOptions()
    options.add_argument('--headless')
    options.add_argument('--no-sandbox')
    options.add_argument("--single-process")
    options.add_argument('--disable-dev-shm-usage')
    options.add_argument('--window-size=1920,1000')
    options.add_argument('--ignore-certificate-errors')
    options.add_argument("--user-agent=Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/87.0.4280.20 Safari/537.36")
    driver = webdriver.Chrome(service=Service(ChromeDriverManager().install()), options=options)
    driver.get(host)
    print('open gitlab', host)
    while True:
        try:
            driver.find_element(By.ID, 'user_login')
            break
        except KeyboardInterrupt:
            return
        except Exception as ex:
            pass
    driver.find_element(By.ID, 'user_login').send_keys(username)
    driver.find_element(By.ID, 'user_password').send_keys(password)
    driver.find_element(By.CLASS_NAME, 'js-sign-in-button').click()
    print('login')
    driver.get(f'{host}/admin/runners')
    print('open runner page')
    time.sleep(2)
    driver.get(f'{host}/admin/runners/new')
    print('open runner new page')
    while True:
        try:
            checkbox = driver.find_element(By.ID,'37')
            break
        except KeyboardInterrupt:
            return
        except:
            pass
    driver.execute_script("arguments[0].click();", checkbox)
    driver.find_element(By.CLASS_NAME, 'js-no-auto-disable').click()
    time.sleep(1)
    print('created new runner')
    while True:
        section = driver.find_elements(By.TAG_NAME, 'code')
        if len(section) == 2:
            break
    print('find token')
    section = section[0]
    token = section.text
    driver.close()
    return token

if __name__ == '__main__':
    if os.path.exists(destination):
        print('destination exists so skip')
    else: 
        token = get_token()
        with open(source, 'r') as f:
            body = f.read()
        body = body.replace('$TOKEN', token)
        with open(destination, 'w') as f:
            f.write(body)
    EOF
  }
}

resource "kubernetes_deployment" "runner" {
  metadata {
    name      = "gitlab-runner"
    namespace = kubernetes_namespace.ns.metadata.0.name
  }
  spec {
    replicas = 1
    selector {
      match_labels = {
        name = "gitlab-runner"
      }
    }
    template {
      metadata {
        labels = {
          name = "gitlab-runner"
        }
      }
      spec {
        service_account_name = kubernetes_service_account.runner_sa.metadata.0.name
        init_container {
          name  = "gitlab-runner-token-getter"
          image = "creaddiscans/selenium_script:0.1"
          security_context {
            run_as_user = 0
          }
          env {
            name = "PYTHONUNBUFFERED"
            value = 1
          }
          volume_mount {
            name       = "config"
            mount_path = "/etc/gitlab-runner/config.toml"
            read_only  = true
            sub_path   = "config.toml"
          }
          volume_mount {
            name       = "config-with-token"
            mount_path = "/etc/gitlab-runner-getter"
          }
          volume_mount {
            name = "script"
            mount_path = "/app"
          }
        }
        container {
          image             = "gitlab/gitlab-runner:latest"
          image_pull_policy = "Always"
          name              = "gitlab-runner"
          resources {
            requests = {
              cpu    = "10m"
              memory = "100Mi"
            }
            limits = {
              cpu    = "500m"
              memory = "200Mi"
            }
          }
          volume_mount {
            name       = "config-with-token"
            mount_path = "/etc/gitlab-runner/config.toml"
            read_only  = true
            sub_path   = "config.toml"
          }
          # volume_mount {
          #   name       = "gitlab-cert"
          #   mount_path = "/etc/gitlab-runner/certs"
          #   read_only  = true
          # }
        }
        volume {
          name = "script"
          config_map {
            name = kubernetes_config_map.runner_script.metadata.0.name
          }
        }
        volume {
          name = "config"
          config_map {
            name = kubernetes_config_map.runner_config.metadata.0.name
          }
        }
        volume {
          name = "config-with-token"
          persistent_volume_claim {
            claim_name = kubernetes_persistent_volume_claim.pvc.metadata.0.name
          }
        }
        # volume {
        #   name = "gitlab-cert"
        #   secret {
        #     secret_name = "${var.prefix.gitlab}-cert"
        #   }
        # }
        restart_policy = "Always"
      }
    }
  }
  depends_on = [kubernetes_stateful_set.gitlab_deploy]
}
