resource "kubernetes_namespace" "ns" {
  metadata {
    name = "minio-storage"
  }
}

resource "kubernetes_persistent_volume_claim" "deploy_pvc" {
  metadata {
    name      = "minio-pvc"
    namespace = kubernetes_namespace.ns.metadata.0.name
  }
  spec {
    access_modes = ["ReadWriteOnce"]
    resources {
      requests = {
        storage = "1Gi"
      }
    }
    storage_class_name = "nfs-volume"
  }
}

resource "kubernetes_config_map" "oidc_script" {
  metadata {
    name = "oidc-script"
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

host = "https://${var.prefix.gitlab}.${var.domain}"
username = "root"
password = "${var.password}"
name = "minio"
redirect_uri = "https://${var.prefix.minio}.${var.domain}/oauth_callback"
group_name = 'consoleAdmin'

def get_token():
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
    driver.get(host+'/admin/applications/new')
    driver.find_element(By.ID, 'doorkeeper_application_name').send_keys(name)
    driver.find_element(By.ID, 'doorkeeper_application_redirect_uri').send_keys(redirect_uri)
    driver.execute_script("arguments[0].click();", driver.find_element(By.ID, 'doorkeeper_application_trusted'))
    driver.execute_script("arguments[0].click();", driver.find_element(By.ID, 'doorkeeper_application_scopes_api'))
    driver.execute_script("arguments[0].click();", driver.find_element(By.ID, 'doorkeeper_application_scopes_openid'))
    driver.execute_script("arguments[0].click();", driver.find_element(By.ID, 'doorkeeper_application_scopes_profile'))
    driver.execute_script("arguments[0].click();", driver.find_element(By.ID, 'doorkeeper_application_scopes_email'))
    driver.find_element(By.CSS_SELECTOR, '[data-testid=save-application-button]').click()
    time.sleep(1)
    client_id = driver.find_element(By.ID, 'application_id').get_attribute('value')
    client_secret = driver.find_element(By.ID, '__BVID__194').get_attribute('value')

    driver.get(host+'/admin/groups/new')
    driver.find_element(By.ID, 'group_path').send_keys(group_name)
    driver.find_element(By.ID, 'group_name').send_keys(group_name)
    time.sleep(3)
    driver.find_element(By.ID, 'new_group').find_element(By.CLASS_NAME, 'btn-confirm').click()

    return client_id, client_secret

if __name__ == '__main__':
  client_id, client_secret = get_token()
  with open('/etc/share/oidc_env.sh', 'w') as f:
    f.write(f'export MINIO_IDENTITY_OPENID_CLIENT_ID={client_id}\n')
    f.write(f'export MINIO_IDENTITY_OPENID_CLIENT_SECRET={client_secret}\n')
    EOF
  }
}

resource "kubernetes_deployment" "minio_deploy" {
  metadata {
    name      = "minio-deploy"
    namespace = kubernetes_namespace.ns.metadata.0.name
    labels = {
      app = "minio"
    }
  }
  spec {
    replicas = 1
    selector {
      match_labels = {
        app = "minio"
      }
    }
    template {
      metadata {
        labels = {
          app = "minio"
        }
      }
      spec {
        init_container {
          name = "gitlab-oidc"
          image = "creaddiscans/selenium_script:0.1"
          volume_mount {
            name = "script"
            mount_path = "/app"
          }
          volume_mount {
            name = "share"
            mount_path = "/etc/share"
          }
        }
        container {
          image             = "minio/minio:latest"
          image_pull_policy = "IfNotPresent"
          name              = "minio"
          security_context {
            run_as_user = 0
          }
          command = ["/bin/sh", "-c"]
          args = [
            "source /etc/share/oidc_env.sh && sleep 5 && mc mb /storage/cnpg && mc mb /storage/airflow && minio server --console-address :9001 /storage --address :9000"
          ]
          resources {
            requests = {
              cpu    = "10m"
              memory = "2048Mi"
            }
            limits = {
              cpu    = "500m"
              memory = "2048Mi"
            }
          }
          env {
            name  = "MINIO_ROOT_USER"
            value = var.minio_creds.username
          }
          env {
            name  = "MINIO_ROOT_PASSWORD"
            value = var.minio_creds.password
          }
          env {
            name  = "TZ"
            value = "Asia/Seoul"
          }
          env {
            name  = "LANG"
            value = "ko_KR.utf8"
          }
          env {
            name  = "MINIO_IDENTITY_OPENID_CONFIG_URL"
            value = "https://${var.prefix.gitlab}.${var.domain}/.well-known/openid-configuration"
          }
          env {
            name  = "MINIO_IDENTITY_OPENID_DISPLAY_NAME"
            value = "gitlab-oidc"
          }
          env {
            name  = "MINIO_IDENTITY_OPENID_SCOPES"
            value = "openid,email"
          }
          env {
            name  = "MINIO_IDENTITY_OPENID_CLAIM_NAME"
            value = "groups_direct"
          }
          env {
            name  = "MINIO_IDENTITY_OPENID_REDIRECT_URI_DYNAMIC"
            value = "on"
          }
          port {
            container_port = 9000
            protocol       = "TCP"
          }
          port {
            container_port = 9001
            protocol       = "TCP"
          }
          volume_mount {
            name       = "minio-volume"
            mount_path = "/storage"
            sub_path   = "minio"
          }
          volume_mount {
            name = "share"
            mount_path = "/etc/share"
          }
        }
        restart_policy = "Always"
        volume {
          name = "minio-volume"
          persistent_volume_claim {
            claim_name = kubernetes_persistent_volume_claim.deploy_pvc.metadata.0.name
          }
        }
        volume {
          name = "share"
          empty_dir {}
        }
        volume {
          name = "script"
          config_map {
            name = kubernetes_config_map.oidc_script.metadata.0.name
          }
        }
      }
    }
  }
}

module "service" {
  source    = "../utils/service"
  domain    = var.domain
  prefix    = var.prefix.minio
  namespace = kubernetes_namespace.ns.metadata.0.name
  port      = 9001
  selector = {
    app = kubernetes_deployment.minio_deploy.metadata.0.labels.app
  }
}

resource "kubernetes_service" "gateway" {
  metadata {
    name      = "minio-gateway-service"
    namespace = kubernetes_namespace.ns.metadata.0.name
  }
  spec {
    port {
      port        = 9000
      target_port = 9000
      protocol    = "TCP"
    }
    selector = {
      app = kubernetes_deployment.minio_deploy.metadata.0.labels.app
    }
  }
}
