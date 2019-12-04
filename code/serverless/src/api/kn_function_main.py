from flask import Flask, request
from common.env import get_port
from common.utils.logger import Logger
from api import last_value_handler, timeseries_handler

logger = Logger().get_logger()

app = Flask(__name__)
HOST = '0.0.0.0'
PORT = get_port()


@app.route('/device/last-value', methods=['GET'])
def handle_get_last_value():
    data = request.form
    logger.info(f"GET request, data: {data}")
    return last_value_handler.get(data)


@app.route('/device/timeseries', methods=['GET'])
def handle_get_timeseries():
    data = request.args
    logger.info(f"GET request, data: {data}")
    return timeseries_handler.get(data)


if __name__ == "__main__":
    logger.info("main run")
    app.run(
        debug=True,
        host=HOST,
        port=PORT
    )