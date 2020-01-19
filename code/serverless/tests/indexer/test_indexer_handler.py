import unittest
from unittest.mock import Mock
from indexer import indexer_handler


class TestIndexerHandler(unittest.TestCase):

    session = None
    __es_container = None

    def setUp(self):
        self.es_client = Mock()

    def test_insert_new_historical(self):
        ######### Given #########
        data = {
            "device": "devicetest",
            "timestamp": 1568559662,
            "temperature": 23,
            "humidity": 56.8,
            "moisture": 9.21
        }
        self.es_client.indices.put_alias = Mock(return_value={})
        self.es_client.index = Mock(return_value={})

        ######### When #########
        result = indexer_handler.handler(self.es_client, "es_alias", data)

        ######### Then #########
        self.assertEqual(str(result.get_data().decode("utf-8")), '{"status": "inserted"}')

