import os
import json
import unittest
from unittest.mock import Mock
from application.indexer.device_handler import DeviceHandler


class TestDeviceHandler(unittest.TestCase):

    def setUp(self):
        self.mqtt_client = Mock()
        self.es_client = Mock()

    def test_consumer_to_read_topic_and_insert_new_historical(self):
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
        os.environ["ES_ALIAS"] = "es-alias"

        self.es_client.indices.put_alias = Mock(return_value={})
        self.es_client.index = Mock(return_value={})

        result = DeviceHandler(self.mqtt_client, self.es_client, "es-alias").handle_on_message(payload, topic)

        self.assertEqual(result, None)


