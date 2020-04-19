import json
from flask import request, Response
from flask import Flask
from flask_httpauth import HTTPBasicAuth
from jsonschema import validate, ValidationError
from common.utils.logger import Logger
from application.back_end.exceptions.api_exceptions import ErrorCode, APIError
from application.back_end.handlers.back_end_service import BackEndService

logger = Logger().get_logger()


QUERY_SCHEMA = {
    "type": "object",
    "properties": {
        "from_date": {"type": "string", "format": "date-time"},
        "to_date": {"type": "string", "format": "date-time"},
        "next_token": {"type": "integer"},
        "max_results": {"type": "integer"}
    },
    "additionalProperties": False
}


def validate_request(body_request: dict, schema: dict):
    try:
        validate(body_request, schema)
    except ValidationError:
        logger.warning("Body request does not respect schema", extra={"body": body_request, "schema": schema})
        raise APIError(error_code=ErrorCode.BAD_REQUEST, message=f"Body request does not respect schema {schema}")


def register_routes(app: Flask, auth: HTTPBasicAuth, back_end_service: BackEndService):

    @app.route('/devices', methods=['GET'])
    @auth.login_required
    def handle_get_devices():
        logger.debug(f"GET list of devices")
        devices = back_end_service.get_devices()
        return Response(json.dumps(devices), mimetype='application/json')

    @app.route('/devices/<string:device>/last-value', methods=['GET'])
    @auth.login_required
    def handle_get_last_value(device):
        logger.debug(f"GET last value for device: {device}")
        last_value = back_end_service.get_last_value(device)
        return Response(json.dumps(last_value), mimetype='application/json')

    @app.route('/devices/<string:device>/timeseries', methods=['GET'])
    @auth.login_required
    def handle_get_timeseries(device):
        logger.debug(f"GET request for device: {device}", extra={"arguments": request.args})
        validate_request(request.args, QUERY_SCHEMA)
        timeseries = back_end_service.get_timeseries(device, request.args)
        return Response(json.dumps(timeseries), mimetype='application/json')
