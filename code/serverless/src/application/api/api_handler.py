import json
from flask import request, Response
from elasticsearch import NotFoundError
from common.utils.logger import Logger
from common.utils.date import get_current_timestamp, get_past_timestamp


logger = Logger().get_logger()
NEXT_TOKEN_PARAM = "nextToken"
MAX_RESULTS_PARAM = "maxResults"
MAX_RESULTS_DEFAULT = 10


def get_offset_and_max_results(request):
    max_results = int(request.args.get(MAX_RESULTS_PARAM, MAX_RESULTS_DEFAULT))
    offset = 0
    if request.args.get(NEXT_TOKEN_PARAM):
        offset = int(request.args.get(NEXT_TOKEN_PARAM))
    return offset, max_results


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


def get_timeseries_query(device: str, offset: int, max_results: int) -> dict:
    return {
        "from": offset, "size": max_results,
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
                                "gte": get_past_timestamp(),
                                "lte": get_current_timestamp()
                            }
                        }
                    }
                ]
            }
        }
    }


def get_search_result(es_client, es_alias: str, body_for_search: dict, offset: int = 0, max_results: int = 0) -> str:
    res = es_client.search(index=es_alias, body=body_for_search)
    total = res['hits']['total']['value']
    result = {"rows": [hit["_source"] for hit in res['hits']['hits']]}
    if offset + max_results <= total:
        result["nextToken"] = offset + max_results
        result["maxResults"] = max_results
    return json.dumps(result)


def get_last_value(es_client, es_alias: str, device: str) -> Response:
    try:
        body_for_search = get_last_value_query(device)
        search_result = get_search_result(es_client, es_alias, body_for_search)
        logger.info(f"search result: {search_result}")
        return Response(search_result, status=200, mimetype="application/json")
    except NotFoundError:
        logger.info("Index not exist return no data")
        return Response('{"message": "no data"}', status=200, mimetype="application/json")
    except Exception as ex:
        logger.error(f"Exception found {str(ex)}")
        return Response('{"message": "Internal Error"}', status=500, mimetype="application/json")


def get_timeseries(es_client, es_alias: str, device: str) -> Response:
    try:
        offset, max_results = get_offset_and_max_results(request)
        body_for_search = get_timeseries_query(device, offset, max_results)
        search_result = get_search_result(es_client, es_alias, body_for_search, offset, max_results)
        logger.info(f"search result: {search_result}")
        return Response(search_result, status=200, mimetype="application/json")
    except NotFoundError:
        logger.info("Index not exist return no data")
        return Response('{"message": "no data"}', status=200, mimetype="application/json")
    except Exception as ex:
        logger.error(f"Exception found {str(ex)}")
        return Response('{"message": "Internal Error"}', status=500, mimetype="application/json")