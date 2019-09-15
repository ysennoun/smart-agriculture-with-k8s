from flask import Flask
from flask import request
from iot.iot_handler import handler
from iot.env import get_port
from common.utils.logger import Logger

logger = Logger().get_logger()

app = Flask(__name__)
HOST = '0.0.0.0'
PORT = get_port()


@app.route('/', methods = ['GET'])
def handle_get():
    return "get hello world baby"
    

@app.route('/', methods = ['POST'])
def handle_post():
    data = request.form
    logger.info(f"POST request, data: {data}")
    return handler(data)


if __name__ == "__main__":
    logger.info("main run")
    app.run(
        debug=True,
        host=HOST,
        port=PORT
    )