import os
import django
from celery import Celery

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'config.settings')

app = Celery('config.settings')
app.config_from_object('django.conf.settings', namespace='CELERY')

app.conf.update(
    CELERY_TASK_SERIALIZER='json',
    CELERY_ACCEPT_CONTENT=['json'],
    CELERY_RESULT_SERIALIZER='json',
    CELERY_TIMEZONE='Asia/Seoul',
    CELERY_ENABLE_UTC=False,
    CELERY_BEAT_SCHEDULER = 'django_celery_beat.schedulers:DatabaseScheduler',
)
app.autodiscover_tasks()

app.conf.beat_schedule = {
    'every-10-seconds': {
        'task':'dashboard.tasks.every_10_sec',
        'schedule':10
    }
}

# django.setup()

# if __name__ == '__main__':
#     app.start()