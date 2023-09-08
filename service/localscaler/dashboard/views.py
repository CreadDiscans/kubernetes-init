from django.shortcuts import render
from django.http import JsonResponse
from .models import Node
import os
from django.conf import settings
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
        node = request.data['node']
        model = Node.objects.get(name=node)
        os.system(f'kubectl cordon {node}')
        os.system(f'kubectl drain --ignore-daemonsets {node}')
        model.status = 'drain'
        model.save()
        return JsonResponse({}, safe=False)

def powerOnReq(request):
    if request.method == 'POST':
        node = request.data['node']
        model = Node.objects.get(name=node)
        os.system(f'bash {os.path.join(settings.BASE_DIR, "wol.sh")} {model.mac} {model.ip}')
        model.status = 'boot'
        model.save()
        return JsonResponse({}, safe=False)
