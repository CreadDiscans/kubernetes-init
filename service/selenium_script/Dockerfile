FROM selenium/standalone-chrome:120.0-20231208

RUN sudo apt update
RUN sudo apt install -y python3-dev python3-pip
RUN python3 -m pip install selenium
RUN python3 -m pip install webdriver-manager

USER root
RUN curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
RUN install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
USER 1200

CMD python3 /app/script.py