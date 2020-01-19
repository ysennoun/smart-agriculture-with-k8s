from flask import request
from common.utils.logger import Logger
from api import api_handler

logger = Logger().get_logger()

NEXT_TOKEN_PARAM = "nextToken"
MAX_RESULTS_PARAM = "maxResults"
MAX_RESULTS_DEFAULT = 10


def get_offset_and_max_results(request):
    max_results = int(request.args.get(MAX_RESULTS_PARAM, MAX_RESULTS_DEFAULT))
    offset = 0
    if request.args.get(NEXT_TOKEN_PARAM):
        offset = int(request.args.get(NEXT_TOKEN_PARAM))
    return offset, max_results


def register_routes(app, es_client, es_alias_raw_data, es_alias_summarized_data):

    @app.route('/device/last-value/<string:device>', methods=['GET'])
    def handle_get_last_value(device):
        logger.info(f"GET last value for device: {device}")
        return api_handler.get_last_value(es_client, es_alias_raw_data, device)

    @app.route('/device/timeseries/<string:device>', methods=['GET'])
    def handle_get_timeseries(device):
        logger.info(f"GET request for device: {device}")
        offset, max_results = get_offset_and_max_results(request)
        return api_handler.get_timeseries(es_client, es_alias_raw_data, device, offset, max_results)

    @app.route('/device/summuared/<string:device>', methods=['GET'])
    def handle_get_summuared(device):
        logger.info(f"GET summared data for device: {device}")
        return api_handler.get_last_value(es_client, es_alias_summarized_data, device)
