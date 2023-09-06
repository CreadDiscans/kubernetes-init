FROM ubuntu:22.04

RUN apt-get -y update
RUN apt-get -y install nginx uwsgi python3 python3-dev python3-pip pkg-config nodejs npm wget apt-utils supervisor redis net-tools
RUN apt-get -y install uwsgi-plugin-python3
RUN apt-get -y install libmysqlclient-dev

RUN mkdir /app
WORKDIR /app
COPY . /app

RUN mkdir /app/log
RUN pip install -r requirements.txt
RUN python3 manage.py migrate
RUN python3 manage.py collectstatic --no-input
RUN cp /app/config/uwsgi.ini /etc/uwsgi/apps-enabled/uwsgi.ini
RUN cp /app/config/nginx.conf /etc/nginx/sites-enabled/nginx.conf
RUN cp /app/config/celery.conf /etc/supervisor/conf.d/celery.conf
RUN rm /etc/nginx/sites-enabled/default

EXPOSE 80
CMD echo $PROMETHEUS > /app/.env; service supervisor start; service uwsgi start; service nginx start; redis-server
