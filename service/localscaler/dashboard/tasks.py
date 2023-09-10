from celery import shared_task
from .models import Node
import requests
from subprocess import Popen, PIPE
import re
import json
import getmac
import os
from django.conf import settings

with open('.env', 'r') as f:
    target = f.read().strip()
url = f'http://{target}:9090/api/v1/query'

@shared_task
def every_10_sec():
    try:
        nodes = {}
        raw = merge(nodes, 'machine_cpu_cores','cpu_max', int)
        merge(nodes, 'node_memory_MemTotal_bytes', 'mem_max', int)
        merge(nodes, 'cluster:namespace:pod_cpu:active:kube_pod_container_resource_requests', 'cpu_req', float)
        merge(nodes, 'cluster:namespace:pod_memory:active:kube_pod_container_resource_requests', 'mem_req', int)
        workers = dict(filter(lambda d:
                              d[0] != 'master' and 
                              all([key in d[1] for key in ['cpu_max', 'cpu_req', 'mem_max', 'mem_req']]), 
                              nodes.items()))
        need_more_node = all([n['cpu_max']*0.8 < n['cpu_req'] or n['mem_max']*0.8 < n['mem_req'] for _, n in workers.items()])
        # TODO cpu / memory 기준으로 요청 < 현재 -1 일대  node 끄기

        node_models = Node.objects.all()
        booting = False
        down_nodes = []
        up_nodes = []
        for node in node_models:
            if node.status == 'drain':
                prome_sql=f'kube_pod_info{"{"}node="{node.name}",created_by_kind!="DaemonSet"{"}"}'
                response = requests.get(url, params={'query': prome_sql})
                if len(response.json()['data']['result']) == 0:
                    os.system(f'/usr/bin/ssh -o StrictHostKeychecking=no root@{node.ip} shutdown now')
                    os.system(f'/usr/local/bin/kubectl delete nodes {node.name}')
                    node.status = 'down'
                    node.save()
                else:
                    os.system(f'/usr/local/bin/kubectl drain --ignore-daemonsets --delete-emptydir-data {node.name}')
            elif node.status == 'boot':
                booting = True
                pid = Popen(["/usr/local/bin/kubectl", "get", "node"], stdout=PIPE)
                s = pid.communicate()[0].decode('utf-8')
                if node.name in s:
                    node.status = 'up'
                    node.save()
                else:
                    requests.get(f'http://localhost/api/magic/{node.name}')
            elif node.status == 'down':
                down_nodes.append(node)
            elif node.status == 'up':
                up_nodes.append(node)
        if need_more_node and len(down_nodes) > 0 and not booting:
            model = down_nodes[0]
            model.status = 'boot'
            model.save()

        for item in raw:
            node_name = item['metric']['node'].strip()
            node_model = Node.objects.filter(name=node_name)
            if node_model.count() == 0:
                ip = item['metric']['instance'].split(':')[0]
                Node(
                    name=node_name,
                    mac=get_mac_address(ip),
                    ip=ip,
                    status='fix' if node_name == 'master' else 'up',
                    info=json.dumps({
                        'cpu':nodes[node_name]['cpu_max'],
                        'memory':round(nodes[node_name]['mem_max']/1024/1024/1024, 2)
                        }, indent=2)
                ).save()

        return json.dumps([[
            n['cpu_max'],
            round(n['cpu_req'], 2),
            round(n['mem_max']/1024/1024/1024, 2),
            round(n['mem_req']/1024/1024/1024, 2)
        ] for _, n in workers.items()])
        # return 'success'
    except Exception as ex:
        return str(ex)

def merge(source, query, key, type):
    data = requests.get(f'{url}?query={query}').json()['data']['result']
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