import os
from flask import Flask
from common.env import get_port
from common.utils.logger import Logger
from common.indexer.elasticsearch_client import get_elasticsearch_client
from indexer import indexer_routes


logger = Logger().get_logger()
app = Flask(__name__)

if __name__ == "__main__":
    logger.info("main run")
    es_client = get_elasticsearch_client()
    es_alias = os.environ["ES_ALIAS"]
    indexer_routes.register_routes(app, es_client, es_alias)

    app.run(
        debug=True,
        host='0.0.0.0',
        port=get_port()
    )
