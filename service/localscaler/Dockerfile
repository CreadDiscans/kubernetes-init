FROM ubuntu:22.04

RUN apt-get update
RUN apt-get -y install apt-utils
RUN apt-get -y install nginx uwsgi python3 python3-dev python3-pip pkg-config supervisor redis net-tools curl
RUN apt-get -y install uwsgi-plugin-python3 libmysqlclient-dev netcat openssh-client wget

RUN wget https://dl.k8s.io/release/v1.27.5/bin/linux/amd64/kubectl
RUN install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
RUN mkdir /root/.kube
RUN mkdir /root/.ssh

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
CMD bash /app/run.sh
