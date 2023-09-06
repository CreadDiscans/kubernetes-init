from selenium import webdriver
from selenium.webdriver.common.by import By
import time
import os

host = os.environ['HOST'] 
username = os.environ['USERNAME'] 
password = os.environ['PASSWORD']
source = os.environ['SOURCE']
destination = os.environ['DESTINATION']

def get_token():
    
    options = webdriver.ChromeOptions()
    options.add_argument('headless')
    options.add_argument('window-size=1920,1000')
    options.add_argument('ignore-certificate-errors')
    options.add_argument("user-agent=Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/87.0.4280.20 Safari/537.36")

    driver = webdriver.Chrome(options)
    driver.get(host)
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

    driver.get(f'{host}/admin/runners')
    time.sleep(2)
    find = False
    for tr in driver.find_elements(By.TAG_NAME, 'tr'):
        tds = tr.find_elements(By.TAG_NAME, 'td')
        if len(tds) == 5:
            a = tds[2].find_element(By.TAG_NAME, 'a')
            url = a.get_attribute('href')
            path = '/admin/'+url.split('/admin/')[1]+'/register'
            register_url = host+path
            find = True
            break
    if not find:
        driver.get(f'{host}/admin/runners/new')
        while True:
            try:
                checkbox = driver.find_element(By.ID,'40')
                break
            except KeyboardInterrupt:
                return
            except:
                pass
        driver.execute_script("arguments[0].click();", checkbox)
        driver.find_element(By.CLASS_NAME, 'js-no-auto-disable').click()
        time.sleep(1)
        path = '/admin/'+driver.current_url.split('/admin/')[1]
        register_url = host + path
    
    driver.get(register_url)
    while True:
        section = driver.find_elements(By.TAG_NAME, 'section')
        if len(section) == 3:
            break
    section = section[0]
    while True:
        try:
            command = section.find_element(By.CLASS_NAME, 'gl-display-flex').text
            break
        except KeyboardInterrupt:
            return
        except:
            pass
    token = command.split('--token')[1].strip()
    driver.close()
    return token

if __name__ == '__main__':
    token = get_token()
    with open(source, 'r') as f:
        body = f.read()
    body = body.replace('$TOKEN', token)
    with open(destination, 'w') as f:
        f.write(body)