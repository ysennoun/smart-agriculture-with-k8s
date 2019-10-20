import json
from flask import Flask, request, Response
from common.env import get_port
from common.utils.logger import Logger
from common.storage.redis_client import get_redis_client


logger = Logger().get_logger()

app = Flask(__name__)
HOST = '0.0.0.0'
PORT = get_port()
TOPIC = "smart-agriculture"


@app.route('/', methods=['POST'])
def handle_post():
    data = request.form
    logger.info(f"POST request, data: {data}")
    return handler(data)


def handler(data: dict) -> Response:
    redis_client = get_redis_client()
    redis_client.rpush(TOPIC, json.dumps(data))
    return Response('{"status": "inserted"}', status=200, mimetype="application/json")


if __name__ == "__main__":
    logger.info("main run")
    app.run(
        debug=True,
        host=HOST,
        port=PORT
    )



