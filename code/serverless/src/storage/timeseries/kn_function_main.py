import json
from flask import Flask, Response
from flask import request
from common.env import get_port
from common.utils.logger import Logger
from common.storage.influxdb_client import InfluxDBIoTClient
from storage.timeseries.model.timeseries_model import get_points_to_insert


logger = Logger().get_logger()

app = Flask(__name__)
HOST = '0.0.0.0'
PORT = get_port()


@app.route('/', methods=['POST'])
def handle_post():
    data = json.loads(request.form)
    logger.info(f"POST request, data: {data}")
    return handler(data)


def handler(data: dict) -> Response:
    client = InfluxDBIoTClient().get_client()
    points = get_points_to_insert(data)
    client.write_points(points)
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



