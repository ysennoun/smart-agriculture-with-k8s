from flask import (make_response, jsonify)
from common.utils.logger import Logger
from api.exceptions.api_exceptions import APIError

logger = Logger().get_logger()


def register_exception_handlers(app):

    @app.errorhandler(404)
    def not_found(error):
        return make_response(jsonify({"message": "Not found"}), 404)

    @app.errorhandler(APIError)
    def special_exception_handler(error: APIError):
        status_code = error.error_code.value.get("status_code")
        return make_response(jsonify(error.format()), status_code)

    @app.errorhandler(Exception)
    def special_exception_handler(error):
        logger.exception("Internal Server Error")
        return make_response(jsonify({"message": "Internal Server Error"}), 500)
