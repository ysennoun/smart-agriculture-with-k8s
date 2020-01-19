import os
from flask import Flask
from common.env import get_port
from common.utils.logger import Logger
from api import api_routes
from common.indexer.elasticsearch_client import get_elasticsearch_client

logger = Logger().get_logger()


if __name__ == "__main__":
    logger.info("main run")
    app = Flask(__name__)
    es_client = get_elasticsearch_client()
    es_alias_raw_data = os.environ["ES_ALIAS_RAW_DATA"]
    es_alias_summarized_data = os.environ["ES_ALIAS_SUMMARIZED_DATA"]
    api_routes.register_routes(app, es_client, es_alias_raw_data, es_alias_summarized_data)

    app.run(
        debug=True,
        host='0.0.0.0',
        port=get_port()
    )
