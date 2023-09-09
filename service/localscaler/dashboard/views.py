from django.shortcuts import render
from django.http import JsonResponse
from django.conf import settings
from .models import Node
import os
import json
# Create your views here.

def home(request):
    return render(request, 'dashboard/index.html',{})

def node(request):
    if request.method == 'GET':
        nodes = Node.objects.all().order_by('-id')
        output = []
        for node in nodes:
            output.append({
                'name':node.name,
                'mac':node.mac,
                'ip':node.ip,
                'status':node.status,
                'info':node.info,
                'updated':node.updated
            })
        return JsonResponse(output, safe=False)
    
def powerOffReq(request):
    if request.method == 'POST':
        data = json.loads(request.body)
        node = data['node']
        model = Node.objects.get(name=node)
        model.status = 'drain'
        model.save()
        os.system(f'/usr/local/bin/kubectl cordon {node}')
        os.system(f'sleep 2 && /usr/local/bin/kubectl drain --ignore-daemonsets --delete-emptydir-data {node} &')
        return JsonResponse({}, safe=False)

def powerOnReq(request):
    if request.method == 'POST':
        data = json.loads(request.body)
        node = data['node']
        model = Node.objects.get(name=node)
        os.system(f'/usr/bin/bash {os.path.join(settings.BASE_DIR, "wol.sh")} {model.mac} {model.ip}')
        model.status = 'boot'
        model.save()
        return JsonResponse({}, safe=False)
