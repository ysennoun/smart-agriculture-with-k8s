import os
from datetime import datetime
import requests
import paho.mqtt.client as mqtt


def send_mqtt_message(payload: str, topic: str, mqtt_broker_url: str, port: int=1883, keep_alive: int=60):
    client = mqtt.Client()
    client.connect(mqtt_broker_url, port, keep_alive)
    client.loop_start()
    client.publish(topic, payload)


def get_current_timestamp() -> int:
    return int(datetime.now().timestamp())


def get_service_url(service_name: str) -> str:
    json_result = os.popen(f'kubectl get svc {service_name} -o json').read()
    external_ip = json_result["status"]["loadBalancer"]["ingress"][0]["ip"]
    port = json_result["status"]["loadBalancer"]["ingress"][0]["port"]
    return str(external_ip + ":" + port)


def get_last_value(api_url: str, device: str) -> dict:
    url = api_url if api_url[len(api_url) - 1] != "/" else api_url[:-1]
    uri = url + "/device/last-value=" + device
    api_response = requests.get(uri)
    return api_response.json()


def get_timeseries(api_url: str, device: str) -> dict:
    url = api_url if api_url[len(api_url) - 1] != "/" else api_url[:-1]
    uri = url + "/device/timeseries=" + device
    api_response = requests.get(uri)
    return api_response.json()
