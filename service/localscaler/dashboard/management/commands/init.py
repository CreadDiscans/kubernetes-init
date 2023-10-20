from django.core.management.base import BaseCommand
from dashboard.models import Config

class Command(BaseCommand):

    def handle(self, *args, **kwargs):
        config = Config.objects.all()
        if config.count() == 0:
            Config().save()