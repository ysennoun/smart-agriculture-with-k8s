FROM balenalib/raspberrypi3-debian-python:3.7

RUN apt update && apt install -y build-essential gcc python-dev

WORKDIR /app
ENV PYTHONPATH /app

ARG MQTT_HOST_IP
ARG MQTT_HOST_PORT
ARG MQTT_TOPIC

ENV PUBLISHING_FREQUENCY 5
ENV MQTT_HOST_IP ${MQTT_HOST_IP}
ENV MQTT_HOST_PORT ${MQTT_HOST_PORT}
ENV MQTT_TOPIC ${MQTT_TOPIC}
ENV MQTT_CA_FILE /app/tls.crt
ENV MQTT_USERNAME_PATH /etc/credentials/username
ENV MQTT_PASSWORD_PATH /etc/credentials/password
ENV MQTT_CLIENT_ID_PATH /etc/credentials/clientId

COPY device/tls.crt ./
COPY device/requirements.txt ./
COPY device/src/ ./

RUN pip install --upgrade pip
RUN pip install -r requirements.txt

CMD [ "python", "device_main.py" ]