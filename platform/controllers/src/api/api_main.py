import os
from flask import Flask
from flask_cors import CORS
from flask_httpauth import HTTPBasicAuth
from common.utils.logger import Logger
from common.env import get_port
from common.storage.elasticsearch_client import get_elasticsearch_client
from api.exceptions import exception_handling
from api.handlers import api_controller
from api.handlers.api_service import ApiService

logger = Logger().get_logger()


class Context:
    pass


def get_es_alias_raw_data():
    return os.environ["ES_ALIAS_RAW_DATA"]


def get_basic_auth_username():
    username_path = os.environ["BASIC_AUTH_USERNAME_PATH"]
    username = open(username_path, 'r').read().rstrip('\n')
    logger.debug(f"username_path: {username_path} and username: {username}")
    return username


def get_basic_auth_password():
    password_path = os.environ["BASIC_AUTH_PASSWORD_PATH"]
    password = open(password_path, 'r').read().rstrip('\n')
    logger.debug(f"password_path: {password_path} and password: {password}")
    return password


def verify_password(username, password):
    return username == get_basic_auth_username() and password == get_basic_auth_password()


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
        context.api_service = ApiService(es_client, es_alias_raw_data)

    # Routes
    api_controller.register_routes(app, auth, context.api_service)

    return app


if __name__ == "__main__":
    logger.info("MAIN RUN")

    app = create_app()

    app.run(
        debug=True,
        host='0.0.0.0',
        port=get_port()
    )
