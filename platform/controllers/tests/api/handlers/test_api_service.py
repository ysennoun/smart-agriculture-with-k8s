import unittest
from unittest.mock import Mock
from common.utils.date import get_current_date, get_date_at_midnight
from api.handlers.api_service import ApiService, QueryArguments


class TestApiService(unittest.TestCase):

    def setUp(self):
        self.es_client = Mock()

    def test_get_offset_and_max_results(self):
        ######### Given #########

        request = Mock()
        request.get = Mock(return_value=11)

        ######### When #########
        query_arguments = QueryArguments.fromDict(request)

        ######### Then #########
        self.assertEqual(query_arguments.offset, 11)
        self.assertEqual(query_arguments.max_results, 11)

    def test_get_devices_query(self):
        ######### Given #########
        query_arguments = QueryArguments(
            offset=0,
            max_results=2,
            from_date=get_date_at_midnight(),
            to_date=get_current_date()
        )

        ######### When #########
        result = ApiService.get_devices_query(query_arguments)

        ######### Then #########
        self.assertEqual(result["aggs"]["devices"]["terms"]["size"], query_arguments.max_results)

    def test_get_last_value_query(self):
        ######### Given #########
        device = "device"

        ######### When #########
        result = ApiService.get_last_value_query(device)
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
        query_arguments = QueryArguments(
            offset=0,
            max_results=2,
            from_date=get_date_at_midnight(),
            to_date=get_current_date()
        )

        ######### When #########
        result = ApiService.get_timeseries_query(device, query_arguments)

        ######### Then #########
        self.assertEqual(result["from"], query_arguments.offset)
        self.assertEqual(result["size"], query_arguments.max_results)
        self.assertEqual(result["query"]["bool"]["must"][0]["term"], {"device": device})

    def test_get_devices(self):
        ######### Given #########
        arguments = {
            "next_token": 0,
            "max_results": 2
        }
        aggregations = {
            "aggregations": {
                "devices": {
                    "doc_count_error_upper_bound": 46,
                    "sum_other_doc_count": 79,
                    "buckets": [
                        {
                            "key": "Device A",
                            "doc_count": 100
                        },
                        {
                            "key": "Device B",
                            "doc_count": 52
                        }
                    ]
                }
            }
        }
        self.es_client.search = Mock(return_value=aggregations)
        api_service = ApiService(self.es_client, "es_alias")

        ######### When #########
        devices = api_service.get_devices(arguments)

        ######### Then #########
        self.assertEqual(devices, {"rows": ["Device A", "Device B"]})

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
        api_service = ApiService(self.es_client, "es_alias")

        ######### When #########
        search_result = api_service.get_search_result(
            {},
            QueryArguments(
                offset=0,
                max_results=2,
                from_date=get_date_at_midnight(),
                to_date=get_current_date()
            )
        )

        ######### Then #########
        expected_search_result = {"rows": [{"id": 1, "device": "device1"}, {"id": 2, "device": "device2"}], "next_token": 1}
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
        api_service = ApiService(self.es_client, "es_alias")

        ######### When #########
        last_value = api_service.get_last_value(device)

        ######### Then #########
        self.assertEqual(last_value, {"rows": [{"id": 1, "device": "device"}]})

    def test_get_timeseries(self):
        ######### Given #########
        device = "device"
        arguments = {
            "next_token": 0,
            "max_results": 2
        }
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
        api_service = ApiService(self.es_client, "es_alias")

        ######### When #########
        timeseries = api_service.get_timeseries(device, arguments)

        ######### Then #########
        self.assertEqual(timeseries, {"rows": [{"id": 1, "device": "device"}], "next_token": 1})


if __name__ == '__main__':
    unittest.main()
