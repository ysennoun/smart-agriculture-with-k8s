import json
from flask import Response
from common.utils.logger import Logger
from common.utils.date import get_current_date_as_string


logger = Logger().get_logger()

DATE_FORMAT = "%Y-%m-%d"


def handler(es_client, es_alias, data: dict) -> Response:
    es_index = es_alias + "-" + get_current_date_as_string(date_format=DATE_FORMAT)
    es_client.indices.put_alias(index=es_index, name=es_alias, ignore=[400, 404])
    es_client.index(index=es_index, body=json.dumps(data))
    return Response('{"status": "inserted"}', status=200, mimetype="application/json")
