import json
from flask import request
from common.utils.logger import Logger
from notification import notification_handler

logger = Logger().get_logger()


def register_routes(app):
    @app.route('/', methods=['POST'])
    def handle_post():
        data = json.loads(request.form)
        logger.info(f"POST request, data: {data}")
        return notification_handler.handler(data)
