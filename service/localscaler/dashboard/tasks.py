from celery import shared_task
from .models import Node, Config
import requests
from subprocess import Popen, PIPE
import re
import json
import getmac
import os
from django.conf import settings
import copy

with open('.env', 'r') as f:
    target = f.read().strip()
url = f'http://{target}:9090/api/v1/query'

@shared_task
def every_tick():
    try:
        nodes = {}
        raw = merge(nodes, 'machine_cpu_cores','cpu_max', int)
        merge(nodes, 'node_memory_MemTotal_bytes', 'mem_max', int)

        node_models = Node.objects.all()
        node_action = False
        for node in node_models:
            if node.status == 'drain':
                node_action = True
                prome_sql=f'kube_pod_info{"{"}node="{node.name}",created_by_kind!="DaemonSet"{"}"}'
                if len(load(prome_sql)) == 0:
                    os.system(f'/usr/bin/ssh -o StrictHostKeychecking=no root@{node.ip} shutdown now')
                    os.system(f'/usr/local/bin/kubectl delete nodes {node.name}')
                    node.status = 'down'
                    node.save()
                else:
                    os.system(f'/usr/local/bin/kubectl cordon {node}') 
                    os.system(f'/usr/local/bin/kubectl drain --ignore-daemonsets --delete-emptydir-data {node.name}')
            elif node.status == 'boot':
                # booting = True
                node_action = True
                pid = Popen(["/usr/local/bin/kubectl", "get", "node"], stdout=PIPE)
                s = pid.communicate()[0].decode('utf-8')
                if node.name in s:
                    node.status = 'up'
                    node.save()
                else:
                    requests.get(f'http://localhost/api/magic/{node.name}')
        
        config = Config.objects.all()[0]
        if config.enable and update_model_info(nodes, raw):
            node_action = True

        if not node_action:
            action, node = autoscale(node_models)
            if action == 'boot':
                nodes = Node.objects.filter(status='down')
                if nodes.count() > 0:
                    node = nodes[0]
                    node.status = 'boot'
                    node.save()
                    return 'boot'
                else:
                    return 'boot but not enough node'
            elif action == 'drain':
                node = Node.objects.get(name=node)
                node.status = 'drain'
                node.save()
                os.system(f'/usr/local/bin/kubectl cordon {node.name}')
                return 'drain'
            else:
                return 'keep'
        return 'action'
    except Exception as ex:
        return str(ex)

def update_model_info(nodes, raw):
    node_action = False
    for item in raw:
        node_name = item['metric']['node'].strip()
        node_model = Node.objects.filter(name=node_name)
        cpu = nodes[node_name]['cpu_max']
        mem = round(nodes[node_name]['mem_max']/1024/1024/1024, 2)
        if node_model.count() == 0:
            ip = item['metric']['instance'].split(':')[0]
            Node(
                name=node_name,
                mac=get_mac_address(ip),
                ip=ip,
                status='fix' if node_name == 'master' else 'up',
                info=json.dumps({
                    'cpu':cpu,
                    'memory':mem
                }, indent=2)
            ).save()
            node_action = True
        else:
            node_item = node_model[0]
            info = json.loads(node_item.info)
            modified = False
            if info['cpu'] != cpu: 
                info['cpu'] = cpu
                modified = True
            if info['memory'] != mem: 
                info['memory'] = mem
                modified = True
            if modified:
                node_item.info = json.dumps(info, indent=2)
                node_item.save()
    return node_action

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
    
def autoscale(models):
    ignore_list = []
    prome_sql=f'kube_pod_info{"{"}created_by_kind="DaemonSet"{"}"}'
    for item in load(prome_sql):
        ignore_list.append(f"{item['metric']['node']}-{item['metric']['pod']}")
    workers = {}
    for model in models:
        if model.status == 'up':
            info = json.loads(model.info)
            workers[model.name] = {
                'cpu':info['cpu'],
                'memory':info['memory']*1024**3,
                'daemonset':{'cpu':0, 'memory':0}, 
                'stack':[]
            }
    
    prome_sql=f'kube_pod_container_resource_requests{"{"}node!="master"{"}"}'
    pods = {}
    for item in load(prome_sql):
        if not 'node' in item['metric']:
            node = 'None'
        else:
            node = item['metric']['node']
        key = f"{node}-{item['metric']['pod']}"
        value = float(item['value'][1])
        type = item['metric']['resource']
        if key in ignore_list:
            if type == 'cpu':
                workers[node]['daemonset']['cpu'] += value
            elif type == 'memory':
                workers[node]['daemonset']['memory'] += value
        else:
            if not key in pods:
                pods[key] = {'cpu':0, 'memory':0}
            if type == 'cpu':
                pods[key]['cpu'] += value
            elif type == 'memory':
                pods[key]['memory'] += value
    
    pods_list = []
    for key, item in pods.items():
        pods_list.append(item)
    # 메모리 기준으로 scale
    pods_list.sort(key=lambda x:-x['memory'])
    # pods_list.append({'cpu':1, 'memory': 512*1024**2}) # 유휴 자원
    worker_names = list(workers.keys())
    idx = 0
    i = 0
    while len(pods_list) > i:
        pod = pods_list[i]
        if len(worker_names) > idx:
            worker = workers[worker_names[idx]]
            if can_allocate(worker, pod):
                worker['stack'].append(pod)
                i += 1
            else:
                idx += 1
        else:
            return 'boot', None
    if len(worker_names) -1 > idx:
        return 'drain', worker_names[-1]
    return None, None

def can_allocate(worker, pod):
    memory = 0
    cpu = 0
    for d in worker['stack']:
        memory += d['memory']
        cpu += d['cpu']
    mem_avail = worker['memory'] > worker['daemonset']['memory'] + memory + pod['memory']
    cpu_avail = worker['cpu'] > worker['daemonset']['cpu'] + cpu + pod['cpu']
    return mem_avail and cpu_avail

def load(prome_sql):
    response = requests.get(url, params={'query': prome_sql})
    return response.json()['data']['result']