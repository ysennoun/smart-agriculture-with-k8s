import json
from flask import Flask, request, Response
from common.env import get_port
from common.utils.logger import Logger
from common.utils.date import get_current_date_as_string
from common.storage.elasticsearch_client import get_elasticsearch_client


logger = Logger().get_logger()

app = Flask(__name__)
HOST = '0.0.0.0'
PORT = get_port()
ES_ALIAS = "smart-agriculture"
DATE_FORMAT = "%Y-%m-%d"


@app.route('/', methods=['POST'])
def handle_post():
    data = json.loads(request.form)
    logger.info(f"POST request, data: {data}")
    return handler(data)


def handler(data: dict) -> Response:
    es_client = get_elasticsearch_client()
    es_index = ES_ALIAS + "-" + get_current_date_as_string(date_format=DATE_FORMAT)
    es_client.indices.put_alias(index=es_index, name=ES_ALIAS, ignore=[400, 404])
    es_client.index(index=es_index, body=json.dumps(data))
    return Response('{"status": "inserted"}', status=200, mimetype="application/json")


if __name__ == "__main__":
    logger.info("main run")
    try:
        app.run(
            debug=True,
            host=HOST,
            port=PORT
        )
    except Exception as ex:
        logger.error(str(ex))



