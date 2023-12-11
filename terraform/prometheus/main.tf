resource "kubernetes_namespace" "ns" {
  metadata {
    name = "monitoring"
  }
}

module "setup" {
  source     = "../utils/apply"
  yaml       = "${path.module}/yaml/manifests-setup.yaml"
  depends_on = [kubernetes_namespace.ns]
}

resource "time_sleep" "wait" {
  create_duration = "30s"
  depends_on      = [module.setup]
}


resource "kubernetes_config_map" "oidc_script" {
  metadata {
    name      = "oidc-script"
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
name = "grafana"
redirect_uri = "https://${var.prefix.grafana}.${var.domain}/login/gitlab"

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

    return client_id, client_secret

if __name__ == '__main__':
  client_id, client_secret = get_token()
  with open('/etc/grafana-raw/grafana.ini', 'r') as f:
    data = f.read()
  data = data.replace('CLIENT_ID', client_id)
  data = data.replace('CLIENT_SECRET', client_secret)
  with open('/etc/grafana/grafana.ini', 'w') as f:
    f.write(data)
    EOF
  }
}

resource "kubernetes_secret" "config" {
  metadata {
    name      = "grafana-config"
    namespace = kubernetes_namespace.ns.metadata.0.name
    labels = {
      "app.kubernetes.io/component" = "grafana"
      "app.kubernetes.io/name"      = "grafana"
      "app.kubernetes.io/part-of"   = "kube-prometheus"
      "app.kubernetes.io/version"   = "9.5.3"
    }
  }
  data = {
    "grafana.ini" = <<EOF
[date_formats]
default_timezone = UTC
[server]
root_url = https://${var.prefix.grafana}.${var.domain}
[auth]
disable_login_form = true
[auth.gitlab]
enabled = true
client_id = 'CLIENT_ID'
client_secret = 'CLIENT_SECRET'
auth_url = https://${var.prefix.gitlab}.${var.domain}/oauth/authorize
token_url = https://${var.prefix.gitlab}.${var.domain}/oauth/token
api_url = https://${var.prefix.gitlab}.${var.domain}/api/v4
scopes = openid email profile api
role_attribute_path: contains(groups[*], 'consoleAdmin') && 'Admin' || 'Viewer'
    EOF
  }
}

module "manifests" {
  source     = "../utils/apply"
  yaml       = "${path.module}/yaml/manifests.yaml"
  depends_on = [time_sleep.wait]
}

module "grafana" {
  source    = "../utils/service"
  domain    = var.domain
  prefix    = var.prefix.grafana
  namespace = kubernetes_namespace.ns.metadata.0.name
  port      = 3000
  selector = {
    "app.kubernetes.io/component" = "grafana"
    "app.kubernetes.io/name"      = "grafana"
    "app.kubernetes.io/part-of" : "kube-prometheus"
  }
  depends_on = [kubernetes_deployment.grafana_deploy]
}
