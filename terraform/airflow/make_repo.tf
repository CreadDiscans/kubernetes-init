resource "kubernetes_config_map" "repo_script" {
  metadata {
    name      = "repo-script"
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
project_name = "airflow"

def start():
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
    driver.get(host+'/projects/new#blank_project')
    driver.find_element(By.ID, 'project_name').send_keys(project_name)
    driver.find_element(By.CSS_SELECTOR, '[data-testid=project-create-button]').click()


if __name__ == '__main__':
  print('start')
  start()
    EOF
  }
}

resource "kubernetes_job" "repo_job" {
  metadata {
    name      = "repo-job"
    namespace = kubernetes_namespace.ns.metadata.0.name
  }
  spec {
    template {
      metadata {}
      spec {
        container {
          name  = "gitlab-repo"
          image = "creaddiscans/selenium_script:0.2"
          volume_mount {
            name       = "script"
            mount_path = "/app"
          }
        }
        volume {
          name = "script"
          config_map {
            name = kubernetes_config_map.repo_script.metadata.0.name
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
  create_duration = "10s"
  depends_on      = [kubernetes_job.repo_job]
}
