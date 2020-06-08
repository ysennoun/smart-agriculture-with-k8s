import os
from flask import Flask
from flask_cors import CORS
from flask_httpauth import HTTPBasicAuth
from common.utils.logger import Logger
from common.env import get_port
from common.storage.elasticsearch_client import get_elasticsearch_client
from application.back_end.exceptions import exception_handling
from application.back_end.handlers import back_end_controller
from application.back_end.handlers.back_end_service import BackEndService

logger = Logger().get_logger()


class Context:
    pass


def get_es_alias_raw_data():
    return os.environ["ES_ALIAS_RAW_DATA"]


def get_basic_auth_username():
    username_path = os.environ["BASIC_AUTH_USERNAME_PATH"]
    return open(username_path, 'r').read().rstrip('\n')


def get_basic_auth_password():
    password_path = os.environ["BASIC_AUTH_PASSWORD_PATH"]
    return open(password_path, 'r').read().rstrip('\n')


def verify_password(username, password):
    if username == get_basic_auth_username():
        return password == get_basic_auth_password()
    return False


def create_app():
    logger.info("STARTING FLASK APPLICATION...")

    app = Flask(__name__, instance_relative_config=True)
    CORS(app)
    auth = HTTPBasicAuth()

    # Basic Authentication
    auth.verify_password(verify_password)

    context = Context()

    # Exception handling
    exception_handling.register_exception_handlers(app)

    with app.app_context():
        logger.info("APP CONTEXT")
        es_client = get_elasticsearch_client()
        es_alias_raw_data = get_es_alias_raw_data()
        context.back_end_service = BackEndService(es_client, es_alias_raw_data)

    # Routes
    back_end_controller.register_routes(app, auth, context.back_end_service)

    return app


if __name__ == "__main__":
    logger.info("MAIN RUN")

    app = create_app()

    app.run(
        debug=True,
        host='0.0.0.0',
        port=get_port()
    )
