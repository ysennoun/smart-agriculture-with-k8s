import os
import json
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


def get_service_url(service_name: str, env: str) -> (str, int):
    result = os.popen(f'kubectl get service {service_name} -n {env} -o json').read()
    json_result = json.loads(result)
    print(json_result)
    external_ip = json_result["status"]["loadBalancer"]["ingress"][0]["ip"]
    port = json_result["status"]["loadBalancer"]["ingress"][0]["port"]
    return external_ip, port


def get_endpoint_value(api_url: str, api_uri: str, device: str) -> dict:
    url = api_url if api_url[len(api_url) - 1] != "/" else api_url[:-1]
    uri = api_uri if api_uri[len(api_url) - 1] != "/" else api_uri[:-1]
    endpoint = url + uri + device
    api_response = requests.get(endpoint)
    return api_response.json()