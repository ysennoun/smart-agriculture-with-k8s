from dataclasses import dataclass
from elasticsearch import Elasticsearch, NotFoundError
from common.utils.logger import Logger
from common.utils.date import get_current_date, get_date_at_midnight


logger = Logger().get_logger()
NEXT_TOKEN_PARAM = "next_token"
MAX_RESULTS_PARAM = "max_results"
FOM_DATE_PARAM = "from_date"
TO_DATE_PARAM = "to_date"
MAX_RESULTS_DEFAULT = 1000


@dataclass
class QueryArguments:
    offset: int
    max_results: int
    from_date: str
    to_date: str

    @staticmethod
    def fromDict(arguments: dict):
        max_results = arguments.get(MAX_RESULTS_PARAM, MAX_RESULTS_DEFAULT)
        offset = arguments.get(NEXT_TOKEN_PARAM, 0)
        from_date = arguments.get(FOM_DATE_PARAM, get_date_at_midnight())
        to_date = arguments.get(TO_DATE_PARAM, get_current_date())

        return QueryArguments(offset=offset, max_results=max_results, from_date=from_date, to_date=to_date)


class BackEndService:

    def __init__(self, es_client: Elasticsearch, es_alias: str):
        self.es_client = es_client
        self.es_alias = es_alias

    @staticmethod
    def get_devices_query(query_arguments: QueryArguments) -> dict:
        return {
            "aggs": {
                "devices": {
                    "terms": {
                        "field": "device",
                        "size": query_arguments.max_results
                    }
                }
            }
        }

    @staticmethod
    def get_last_value_query(device: str) -> dict:
        return {
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

    @staticmethod
    def get_timeseries_query(device: str, query_arguments: QueryArguments) -> dict:
        return {
            "from": query_arguments.offset, "size": query_arguments.max_results,
            "query": {
                "bool": {
                    "must": [
                        {
                            "term": {
                                "device": device
                            }
                        },
                        {
                            "range": {
                                "timestamp": {
                                    "gte": query_arguments.from_date,
                                    "lte": query_arguments.to_date
                                }
                            }
                        }
                    ]
                }
            }
        }

    def get_devices(self, arguments: dict) -> dict:
        query_arguments = QueryArguments.fromDict(arguments)
        body_for_search = self.get_devices_query(query_arguments)
        res = self.es_client.search(index=self.es_alias, body=body_for_search, ignore=[404])
        result = {"rows": [hit["key"] for hit in res['aggregations']['devices']['buckets']]}
        logger.debug("Get devices", extra={"result": result})
        return result

    def get_search_result(self, body_for_search: dict,
                          query_arguments: QueryArguments = QueryArguments(0, MAX_RESULTS_DEFAULT, get_date_at_midnight(), get_current_date())) -> dict:
        res = self.es_client.search(index=self.es_alias, body=body_for_search, ignore=[404])
        total = res['hits']['total']['value']
        search_result = {"rows": [hit["_source"] for hit in res['hits']['hits']]}
        if (query_arguments.offset + 1) * query_arguments.max_results <= total:
            search_result[NEXT_TOKEN_PARAM] = query_arguments.offset + 1
        logger.debug("Get search result", extra={"search_result": search_result})
        return search_result

    def get_last_value(self, device: str) -> dict:
        body_for_search = self.get_last_value_query(device)
        search_result = self.get_search_result(body_for_search)
        logger.debug("Get last value", extra={"search_result": search_result})
        return search_result

    def get_timeseries(self, device: str, arguments: dict) -> dict:
        query_arguments = QueryArguments.fromDict(arguments)
        body_for_search = self.get_timeseries_query(device, query_arguments)
        search_result = self.get_search_result(body_for_search, query_arguments)
        logger.debug("Get search result", extra={"search_result": search_result})
        return search_result
