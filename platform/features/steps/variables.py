import os


def get_environment() -> str:
    return os.environ["ENVIRONMENT"]


def get_api_user() -> str:
    return os.environ["API_USER"]


def get_api_user_pass() -> str:
    return os.environ["API_USER_PASS"]


def get_mqtt_user() -> str:
    return os.environ["MQTT_USER"]


def get_mqtt_user_pass() -> str:
    return os.environ["MQTT_USER_PASS"]