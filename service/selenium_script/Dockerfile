FROM selenium/standalone-chrome:latest

RUN sudo apt update
RUN sudo apt install -y python3 python3-dev python3-pip
RUN python3 -m pip install selenium
RUN python3 -m pip install webdriver-manager

CMD python3 /app/script.py