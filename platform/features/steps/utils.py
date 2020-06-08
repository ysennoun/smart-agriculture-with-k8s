import os
import json
import time
import datetime
import logging
from steps import variables as var


def get_current_timestamp() -> str:
    return f"{datetime.datetime.now():%Y-%m-%dT%H:%M:%SZ}"


def get_past_timestamp(minutes: int) -> str:
    return f"{(datetime.datetime.now() - datetime.timedelta(minutes=minutes)):%Y-%m-%dT%H:%M:%SZ}"


def send_mqtt_payload(mqtt_topic: str, mqtt_payload: dict):
    result = os.popen(f'kubectl get service smart-agriculture-vernemq -n {var.get_environment()} -o json').read()
    mqtt_broker_ip = json.loads(result)["status"]["loadBalancer"]["ingress"][0]["ip"]

    mqtt_cmd = f"mosquitto_pub  -d -u {var.get_mqtt_user()} -P {var.get_mqtt_user_pass()} -h {mqtt_broker_ip} -p 8883 " \
               f"-t '{mqtt_topic}' -m '{mqtt_payload}' --cafile /etc/ssl/vernemq/tls.crt"
    mqtt_result = os.popen(mqtt_cmd).read()
    logging.info(f"Result for senfing message: {mqtt_result}")


def get_api_response(uri: str) -> str:
    result = os.popen(f'kubectl get service api -n {var.get_environment()} -o json').read()
    api_ip = json.loads(result)["status"]["loadBalancer"]["ingress"][0]["ip"]
    api_cmd = f'curl -s --cacert /etc/ssl/api/tls.crt -u "{var.get_api_user()}:{var.get_api_user_pass()}" ' \
                   f'"https://{api_ip}:443{uri}"'
    api_response = os.popen(api_cmd).read()
    logging.info(f"Response from api: {api_response}")
    return api_response