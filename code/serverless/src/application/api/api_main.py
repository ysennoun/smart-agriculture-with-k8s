from flask import Flask, Response
from common.env import get_port
from common.utils.logger import Logger
from common.storage.elasticsearch_client import get_elasticsearch_client
from api import env, api_handler


logger = Logger().get_logger()
app = Flask(__name__)
es_client = get_elasticsearch_client()
es_alias_raw_data = env.get_es_alias_raw_data()
es_alias_summarized_data = env.get_es_alias_summarized_data()


@app.route('/device/last-value/<string:device>', methods=['GET'])
def handle_get_last_value(device):
    logger.info(f"GET last value for device: {device}")
    return api_handler.get_last_value(es_client, es_alias_raw_data, device)

@app.route('/device/timeseries/<string:device>', methods=['GET'])
def handle_get_timeseries(device):
    logger.info(f"GET request for device: {device}")
    return api_handler.get_timeseries(es_client, es_alias_raw_data, device)


if __name__ == "__main__":
    logger.info("main run")
    app.run(
        debug=True,
        host='0.0.0.0',
        port=get_port()
    )