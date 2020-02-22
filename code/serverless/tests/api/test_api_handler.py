import unittest
from unittest.mock import Mock, MagicMock, patch
from api import api_handler


class TestApiHandler(unittest.TestCase):

    def setUp(self):
        self.es_client = Mock()

    def test_get_offset_and_max_results(self):
        ######### Given #########

        request = Mock()
        request.args.get = Mock(return_value="11")

        ######### When #########
        offset, max_results = api_handler.get_offset_and_max_results(request)

        ######### Then #########
        self.assertEqual(offset, 11)
        self.assertEqual(max_results, 11)


    def test_get_last_value_query(self):
        ######### Given #########
        device = "device"

        ######### When #########
        result = api_handler.get_last_value_query(device)
        ######### Then #########
        expected_result = {
            "query": {
                "term": {
                    "device": device
                }
            },
            "sort": [
                {
                    "timestamp": {
                        "order": "desc"
                    }
                }
            ],
            "size": 1
        }
        self.assertEqual(result, expected_result)

    def test_get_timeseries_query(self):
        ######### Given #########
        device = "device"
        offset = 0
        max_results = 2

        ######### When #########
        result = api_handler.get_timeseries_query(device, offset, max_results)

        ######### Then #########
        self.assertEqual(result["from"], offset)
        self.assertEqual(result["size"], max_results)
        self.assertEqual(result["query"]["bool"]["must"][0]["term"], {"device": device})

    def test_get_search_result(self):
        ######### Given #########
        hits = {
            "hits": {
                "hits":
                    [
                        {"_source": {"id": 1, "device": "device1"}},
                        {"_source": {"id": 2, "device": "device2"}}
                    ],
                "total": {
                    "value": 5
                }
            }
        }
        self.es_client.search = Mock(return_value=hits)

        ######### When #########
        search_result = api_handler.get_search_result(self.es_client, "es_alias", {}, 0, 2)

        ######### Then #########
        expected_search_result = '{"rows": [{"id": 1, "device": "device1"}, {"id": 2, "device": "device2"}], "nextToken": 2, "maxResults": 2}'
        self.assertEqual(search_result, expected_search_result)

    def test_get_last_value(self):
        ######### Given #########
        device = "device"
        hits = {
            "hits": {
                "hits":
                    [
                        {"_source": {"id": 1, "device": device}}
                    ],
                "total": {
                    "value": 5
                }
            }
        }
        self.es_client.search = Mock(return_value=hits)

        ######### When #########
        last_value = api_handler.get_last_value(self.es_client, "es_alias", device)

        ######### Then #########
        self.assertEqual(last_value.status_code, 200)
        self.assertEqual(last_value.json["rows"][0], {"id": 1, "device": device})


    @patch("api.api_handler.get_offset_and_max_results")
    def test_get_timeseries(self, get_offset_and_max_results_mock: MagicMock):
        ######### Given #########
        device = "device"
        hits = {
            "hits": {
                "hits":
                    [
                        {"_source": {"id": 1, "device": device}}
                    ],
                "total": {
                    "value": 5
                }
            }
        }
        self.es_client.search = Mock(return_value=hits)
        get_offset_and_max_results_mock.return_value = (0, 2)

        ######### When #########
        timeseries = api_handler.get_timeseries(self.es_client, "es_alias", device)

        ######### Then #########
        self.assertEqual(timeseries.status_code, 200)
        self.assertEqual(timeseries.json["rows"][0], {"id": 1, "device": device})


if __name__ == '__main__':
    unittest.main()