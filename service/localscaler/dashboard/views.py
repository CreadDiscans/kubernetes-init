from django.shortcuts import render
from django.http import JsonResponse
from .models import Node
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