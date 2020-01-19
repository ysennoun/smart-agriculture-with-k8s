import json
from flask import Response
from common.utils.date import get_current_timestamp, get_past_timestamp


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
            "term": {
                "device": device
            },
            "range": {
                "age": {
                    "gte": get_past_timestamp(),
                    "lte": get_current_timestamp()
                }
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
    body_for_search = get_last_value_query(device)
    search_result = get_search_result(es_client, es_alias, body_for_search)
    return Response(search_result, status=200, mimetype="application/json")


def get_timeseries(es_client, es_alias: str, device: str, offset: int, max_results: int) -> Response:
    body_for_search = get_timeseries_query(device, offset, max_results)
    search_result = get_search_result(es_client, es_alias, body_for_search, offset, max_results)
    return Response(search_result, status=200, mimetype="application/json")
