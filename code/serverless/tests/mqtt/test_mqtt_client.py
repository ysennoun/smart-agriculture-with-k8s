import os
import json
import unittest
import requests_mock
import docker
import time
from mqtt.mqtt_client import MqttClient


class TestMqttClient(unittest.TestCase):

    __mqtt_container = None

    def setUp(self):
        # run a Mqtt broker within a docker container
        client = docker.from_env()
        self.__mqtt_container = client.containers.run(
            image="eclipse-mosquitto",
            ports={"1883/tcp": 1883, "9001/tcp": 9001},
            detach=True
        )
        time.sleep(20)  # wait container to be available

    def tearDown(self):
        if self.__mqtt_container:
            self.__mqtt_container.stop()
            self.__mqtt_container.remove()

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
        os.environ["BROKERS_URL"] = "http://" +
        os.environ["CE-Type"] = ""

        with requests_mock.mock() as mocker:
            mocker.post("http://" + istio_ip_address, text=expected_response)
            try:
                MqttClient().handle_on_message(payload, topic)
                assert True
            except TypeError:
                assert False



