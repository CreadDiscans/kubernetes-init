from django.shortcuts import render
from django.http import JsonResponse
from django.conf import settings
from .models import Node, Config
import os
import json
from django.views.decorators.csrf import csrf_exempt
# Create your views here.

def home(request):
    return render(request, 'dashboard/index.html',{})

def node(request):
    if request.method == 'GET':
        nodes = Node.objects.all().order_by('-id')
        config = Config.objects.all()[0]
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
        return JsonResponse({
            'nodes':output,
            'config':{
                'enable':config.enable,
            }
        }, safe=False)
    
@csrf_exempt
def config(request):
    if request.method == 'PUT':
        data = json.loads(request.body)
        config = Config.objects.all()[0]
        if 'enable' in data:
            config.enable = data['enable']
            config.save()
        return JsonResponse({'message':'success'})

@csrf_exempt
def powerOffReq(request):
    if request.method == 'POST':
        data = json.loads(request.body)
        node = data['node']
        model = Node.objects.get(name=node)
        model.status = 'drain'
        model.save()
        return JsonResponse({}, safe=False)

@csrf_exempt
def powerOnReq(request):
    if request.method == 'POST':
        data = json.loads(request.body)
        node = data['node']
        model = Node.objects.get(name=node)
        model.status = 'boot'
        model.save()
        return JsonResponse({}, safe=False)

def magic_packet(request, node):
    if request.method == 'GET':
        model = Node.objects.get(name=node)
        broadcast = '.'.join(model.ip.split('.')[:3] + ['255'])
        os.system(f'/usr/bin/wakeonlan -i {broadcast} {model.mac}')
        return JsonResponse({}, safe=False)
        