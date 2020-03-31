import os
import json
import time
from datetime import datetime
from kubernetes import config
from kubernetes.client import Configuration
from kubernetes.client.api import core_v1_api
from steps import variables as var


def get_current_timestamp() -> str:
    return f"{datetime.now():%Y-%m-%dT%H:%M:%SZ}"


def get_core_v1():
    config.load_kube_config()
    c = Configuration()
    c.assert_hostname = False
    Configuration.set_default(c)
    return core_v1_api.CoreV1Api()


def run_pod(api_instance, pod_name: str, pod_manifest: dict) -> str:
    print("Pod %s does not exist. Creating it..." % pod_name)
    namespace = var.get_environment()
    api_instance.create_namespaced_pod(body=pod_manifest, namespace=namespace)
    while True:
        resp = api_instance.read_namespaced_pod(name=pod_name, namespace=namespace)
        if resp.status.phase != 'Pending':
            break
        time.sleep(1)
    print("Pod created done.")

    time.sleep(200)

    return api_instance.read_namespaced_pod_log(name=pod_name, namespace=namespace)


def delete_pod(api_instance, pod_name: str):
    api_instance.delete_namespaced_pod(name=pod_name,
                                       namespace=var.get_environment())


def get_mqtt_pod_manifest(mqtt_pod_name: str, mqtt_payload: str, mqtt_topic: dict) -> dict:
    result = os.popen(f'kubectl get service smart-agriculture-vernemq -n {var.get_environment()} -o json').read()
    mqtt_broker_ip = json.loads(result)["status"]["loadBalancer"]["ingress"][0]["ip"]

    mqtt_cmd = f"mosquitto_pub  -d -u {var.get_mqtt_user()} -P {var.get_mqtt_user_pass()} -h {mqtt_broker_ip} -p 8883 " \
               f"-t '{mqtt_topic}' -m '{mqtt_payload}' --cafile /etc/ssl/vernemq/tls.crt"

    mqtt_pod_manifest = {
        'apiVersion': 'v1',
        'kind': 'Pod',
        'metadata': {
            'name': mqtt_pod_name,
            'namespace': var.get_environment()
        },
        'spec': {
            'containers': [{
                'image': var.get_docker_image(),
                'name': mqtt_pod_name,
                'args': [
                    '/bin/sh',
                    '-c',
                    f'{mqtt_cmd};sleep 600'
                ],
                'volumeMounts':[{
                    'name': 'vernemq-certificates',
                    'mountPath': '/etc/ssl/vernemq/tls.crt',
                    'subPath': 'tls.crt',
                    'readOnly': True
                }]
            }],
            'volumes': [{
                'name': 'vernemq-certificates',
                'secret': {
                    'secretName': 'vernemq-certificates-secret'
                }
            }],
            'restartPolicy': 'Never'
        }
    }

    print(f"mqtt_pod_manifest: {mqtt_pod_manifest}")
    return mqtt_pod_manifest


def get_back_end_pod_manifest(back_end_pod_name: str, uri: str) -> dict:
    back_end_cmd = f'curl -s -u "{var.get_back_end_user()}:{var.get_back_end_user_pass()}" ' \
    f'https://back-end.{var.get_environment()}.svc.cluster.local:443{uri} --cacert /etc/ssl/back-end/tls.crt'

    return {
        'apiVersion': 'v1',
        'kind': 'Pod',
        'metadata': {
            'name': back_end_pod_name,
            'namespace': var.get_environment()
        },
        'spec': {
            'containers': [{
                'image': var.get_docker_image(),
                'name': back_end_pod_name,
                "args": [
                    "/bin/sh",
                    "-c",
                    f"{back_end_cmd};sleep 600"
                ],
                'volumeMounts':[{
                    'name': 'back-end-certificates',
                    'mountPath': '/etc/ssl/back-end/tls.crt',
                    'subPath': 'tls.crt',
                    'readOnly': True
                }]
            }],
            'volumes': [{
                'name': 'back-end-certificates',
                'secret': {
                    'secretName': 'back-end-certificates-secret'
                }
            }],
            'restartPolicy': 'Never'
        }
    }