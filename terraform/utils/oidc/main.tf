
resource "kubernetes_config_map" "oidc_script" {
  metadata {
    name      = "oidc-script"
    namespace = var.namespace
  }
  data = {
    "script.py" = <<EOF
from selenium import webdriver
from selenium.webdriver.common.by import By
from selenium.webdriver.chrome.service import Service
from webdriver_manager.chrome import ChromeDriverManager
import time
import os

host = "${var.gitlab_host}"
username = "root"
password = "${var.password}"
name = "${var.name}"
redirect_uri = "${var.redirect_uri}"

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
    time.sleep(5)
    client_id = driver.find_element(By.ID, 'application_id').get_attribute('value')
    while True:
      try:
        client_secret = driver.find_element(By.ID, '__BVID__194').get_attribute('value')
        break
      except:
        print('error get secret, retrying')
        time.sleep(10)

    return client_id, client_secret

if __name__ == '__main__':
  print('start')
  client_id, client_secret = get_token()
  os.system(f'kubectl create secret generic ${local.secret_name} --from-literal=client_id={client_id} --from-literal=client_secret={client_secret}')
    EOF
  }
}

resource "kubernetes_service_account" "oidc_sa" {
  metadata {
    name      = "oidc-service-account"
    namespace = var.namespace
  }
}

resource "kubernetes_role" "oidc_role" {
  metadata {
    name      = "oidc-role"
    namespace = var.namespace
  }
  rule {
    api_groups = ["*"]
    resources  = ["secrets"]
    verbs      = ["get", "list", "watch", "create", "update"]
  }
}

resource "kubernetes_role_binding" "oidc_role_binding" {
  metadata {
    name      = "oidc-role-binding"
    namespace = var.namespace
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "Role"
    name      = kubernetes_role.oidc_role.metadata.0.name
  }
  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account.oidc_sa.metadata.0.name
    namespace = var.namespace
  }
}

resource "kubernetes_job" "oidc_job" {
  metadata {
    name      = "oidc-job"
    namespace = var.namespace
  }
  spec {
    template {
      metadata {}
      spec {
        service_account_name = kubernetes_service_account.oidc_sa.metadata.0.name
        container {
          name  = "gitlab-oidc"
          image = "creaddiscans/selenium_script:0.2"
          volume_mount {
            name       = "script"
            mount_path = "/app"
          }
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
  timeouts {
    create = "10m"
    update = "10m"
  }
  wait_for_completion = true
}


resource "time_sleep" "wait" {
  create_duration = "30s"
  depends_on      = [kubernetes_job.oidc_job]
}
