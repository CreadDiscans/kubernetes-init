from celery import shared_task
from .models import Node
import requests
from subprocess import Popen, PIPE
import re

@shared_task
def every_10_sec():
    try:
        # TODO cpu 기준으로 요청 > 현재 일때 node 켜기
        # TODO cpu / memory 기준으로 요청 < 현재 -1 일대  node 끄기
        # TODO memory 기준으로 요청 > 현재 일대 node 켜기

        # TODO 기록 안된 node 있을때 node 추가 하기

        data = requests.get('http://prometheus-k8s.monitoring:9090/api/v1/query?query=machine_cpu_cores').json()['data']['result']
        nodes = {}
        for item in data:
            ip = item['metric']['instance'].split(':')[0]
            nodes[item['metric']['node']] = {
                'ip':ip,
                'cpu':int(item['value'][1]),
                'mac':get_mac_address(ip)
            }
        
        return 'success'
    except Exception as ex:
        return str(ex)
    
def get_mac_address(ip):

    pid = Popen(["arp", "-n", ip], stdout=PIPE)
    s = pid.communicate()[0].decode('utf-8')
    mac = re.search(r"(([a-f\d]{1,2}\:){5}[a-f\d]{1,2})", s).groups()[0]
    return mac