from django.db import models

# Create your models here.
class Node(models.Model):

    name = models.CharField(max_length=100)
    mac = models.CharField(max_length=100)
    ip = models.CharField(max_length=100)
    status = models.CharField(max_length=100)
    info = models.CharField(max_length=100)
    updated = models.DateTimeField(auto_now=True)
    
class Config(models.Model):

    enable = models.BooleanField(default=True)