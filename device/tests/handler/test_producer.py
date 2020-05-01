import os
import pathlib
import json
import unittest
from unittest.mock import MagicMock
from handler.producer import Producer


class TestProducer(unittest.TestCase):

    @classmethod
    def get_resources_path(cls):
        return os.path.normpath(os.path.join(pathlib.Path(__file__).parent.absolute(), "..", "resources"))

    def setUp(self):
        os.environ["MQTT_CLIENT_ID_PATH"] = f"{self.get_resources_path()}/clientID"

    def test_should_get_payload(self):
        # Given
        producer = Producer()
        producer.get_moisture = MagicMock(return_value=25)
        producer.get_temperature = MagicMock(return_value=11)

        # When
        payload = producer.get_payload()
        json_payload = json.loads(payload)

        # Then
        self.assertEqual(json_payload["device"], "device-test")
        self.assertEqual(json_payload["temperature"], 11)
        self.assertEqual(json_payload["moisture"], 25)


