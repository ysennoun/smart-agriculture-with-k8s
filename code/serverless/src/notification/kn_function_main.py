import json
from flask import Flask, request, Response
from common.env import get_port
from common.utils.logger import Logger
from notification.notification_by_email import is_notification_activated, send_email

logger = Logger().get_logger()

app = Flask(__name__)
HOST = '0.0.0.0'
PORT = get_port()


def _get_status_response(status):
    return Response(
        json.dumps({"status": status}),
        status=200,
        mimetype="application/json"
    )


@app.route('/', methods=['POST'])
def handle_post():
    data = json.loads(request.form)
    logger.info(f"POST request, data: {data}")
    return handler(data)


def handler(data: dict) -> Response:
    if is_notification_activated(data):
        send_email(data)
    return _get_status_response("inserted")


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
