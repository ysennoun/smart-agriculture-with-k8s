import json
from flask import request
from common.utils.logger import Logger
from indexer import index_handler


logger = Logger().get_logger()


def register_routes(app, es_client, es_alias: str):
    @app.route('/', methods=['POST'])
    def handle_post():
        data = json.loads(request.form)
        logger.info(f"POST request, data: {data}")
        return index_handler.handler(es_client, es_alias, data)
