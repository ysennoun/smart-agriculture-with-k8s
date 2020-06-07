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


def get_back_end_response(uri: str) -> str:
    result = os.popen(f'kubectl get service back-end -n {var.get_environment()} -o json').read()
    back_end_ip = json.loads(result)["status"]["loadBalancer"]["ingress"][0]["ip"]
    back_end_cmd = f'curl -s --cacert /etc/ssl/back-end/tls.crt -u "{var.get_back_end_user()}:{var.get_back_end_user_pass()}" ' \
                   f'"https://{back_end_ip}:443{uri}"'
    back_end_response = os.popen(back_end_cmd).read()
    logging.info(f"Response from back end: {back_end_response}")
    return back_end_response