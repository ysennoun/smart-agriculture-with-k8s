import os
import json
import unittest
import requests_mock
from connector.mqtt_client import MqttClient


class TestMqttClient(unittest.TestCase):

    def setUp(self):
        # run a Mqtt broker within a docker container
        os.system("docker run -it -p 1883:1883 -p 9001:9001 eclipse-mosquitto")
        os.environ["BROKERS_URL"] = ""


    def tearDown(self):
        container_ids = "$(docker ps -a -q  --filter ancestor=eclipse-mosquitto)"
        os.system(f"docker container stop {container_ids}")
        os.system(f"docker container rm {container_ids}")

    def test_connector_to_read_topic_and_sned_to_broker(self):
        message = {
            "payload": json.dumps({
                "device": "smart-device",
                "timestamp": 1568043219,
                "temperature": 32,
                "humidity": 76,
                "moisture": 44
            }),
            "topic": "test/test"
        }
        istio_ip_address = "test.com"
        os.environ["ISTIO_INGRESS_GATEWAY_IP_ADDRESS"] = istio_ip_address
        expected_response = "response"

        with requests_mock.mock() as mocker:
            mocker.post('http://' + istio_ip_address, text=expected_response)
            try:
                MqttClient().on_message(None, None, message)
                assert False
            except TypeError:
                assert True



