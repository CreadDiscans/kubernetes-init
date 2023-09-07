from celery import shared_task
from .models import Node
import requests
from subprocess import Popen, PIPE
import re
import json
import getmac
import os

with open('.env', 'r') as f:
    target = f.read().strip()
url = f'http://{target}:9090/api/v1/query?query='

@shared_task
def every_10_sec():
    try:
        nodes = {}
        raw = merge(nodes, 'machine_cpu_cores','cpu_max', int)
        merge(nodes, 'node_memory_MemTotal_bytes', 'mem_max', int)
        merge(nodes, 'cluster:namespace:pod_cpu:active:kube_pod_container_resource_requests', 'cpu_req', float)
        merge(nodes, 'cluster:namespace:pod_memory:active:kube_pod_container_resource_requests', 'mem_req', int)
        need_more_node = all([n['cpu_max']*0.9 < n['cpu_req'] or n['mem_max']*0.9 < n['mem_req'] for _, n in nodes.items()])
        if need_more_node:
            if Node.objects.filter(status='booting').count() > 0:
                print('booting')
            elif Node.objects.filter(status='down').count() > 0:
                node = Node.objects.filter(status='down')[0]
                print('boot', node.name, node.ip, node.mac)
            else:
                print('no more node')

        # TODO cpu / memory 기준으로 요청 < 현재 -1 일대  node 끄기

        node_models = Node.objects.all()
        for node in node_models:
            find = False
            for item in raw:
                node_name = item['metric']['node'].strip()
                if node.name == node_name:
                   find = True
                   break
            if not find:
                node.status = 'down' 

        for item in raw:
            node_name = item['metric']['node'].strip()
            node_model = Node.objects.filter(name=node_name)
            if node_model.count() == 0:
                ip = item['metric']['instance'].split(':')[0]
                Node(
                    name=node_name,
                    mac=get_mac_address(ip),
                    ip=ip,
                    status='up',
                    info=json.dumps({
                        'cpu':nodes[node_name]['cpu_max'],
                        'memory':round(nodes[node_name]['mem_max']/1024/1024/1024, 2)
                        }, indent=2)
                ).save()
            else:
                node_model[0].status = 'running'
                node_model[0].save()
        return 'success'
    except Exception as ex:
        return str(ex)
    
def merge(source, query, key, type):
    data = requests.get(f'{url}{query}').json()['data']['result']
    for item in data:
        if 'node' in item['metric']:
            node_name = item['metric']['node'].strip()
        else:
            node_name = item['metric']['instance'].strip()
        if not node_name in source:
            source[node_name] = {}
        if not key in source[node_name]:
            source[node_name][key] = 0
        value = type(item['value'][1])
        source[node_name][key] += value
    return data

def get_mac_address(ip):
    pid = Popen(["hostname", "-I"], stdout=PIPE)
    s = pid.communicate()[0].decode('utf-8')
    myip = s.split(' ')[0]
    if myip == ip:
        mac = getmac.get_mac_address()
        return mac
    else:
        pid = Popen(["arp", "-n", ip], stdout=PIPE)
        s = pid.communicate()[0].decode('utf-8')
        mac = re.search(r"(([a-f\d]{1,2}\:){5}[a-f\d]{1,2})", s).groups()[0]
        return mac