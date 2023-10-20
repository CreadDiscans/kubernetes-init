from django.urls import path
from dashboard import views
urlpatterns = [
    path('', views.home), 
    path('api/node/', views.node),
    path('api/config/', views.config),
    path('api/power/off', views.powerOffReq),
    path('api/power/on', views.powerOnReq),
    path('api/magic/<str:node>', views.magic_packet)
]