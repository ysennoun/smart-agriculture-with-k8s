import os
import json
import unittest
import requests_mock
from device.mqtt_client import MqttClient


class TestMqttClient(unittest.TestCase):

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



