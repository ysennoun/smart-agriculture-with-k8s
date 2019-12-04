import os
import json
import unittest
import requests_mock
from mqtt.mqtt_client import MqttClient


class TestMqttClient(unittest.TestCase):

    def setUp(self):
        # run a Mqtt broker within a docker container
        os.system("docker run -it -p 1883:1883 -p 9001:9001 eclipse-mosquitto")

    def tearDown(self):
        container_ids = "$(docker ps -a -q  --filter ancestor=ecli-mosquitto)"
        print(os.system(container_ids))
        print("eee")
        os.system(f"docker container stop {container_ids}")
        os.system(f"docker container rm {container_ids}")

    def test_consumer_to_read_topic_and_send_to_broker(self):
        topic = "test/test"
        payload = json.dumps({
            "payload": json.dumps({
                "device": "smart-device",
                "timestamp": 1568043219,
                "temperature": 32,
                "humidity": 76,
                "moisture": 44
            }),
            "topic": topic
        })
        istio_ip_address = "test.com"
        os.environ["ISTIO_INGRESS_GATEWAY_IP_ADDRESS"] = istio_ip_address
        expected_response = "response"
        os.environ["BROKERS_URL"] = "http://" + istio_ip_address
        os.environ["CE-Type"] = ""

        with requests_mock.mock() as mocker:
            mocker.post("http://" + istio_ip_address, text=expected_response)
            try:
                MqttClient().handle_on_message(payload, topic)
                assert True
            except TypeError:
                assert False



