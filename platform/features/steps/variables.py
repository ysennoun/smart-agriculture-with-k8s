import os


def get_environment() -> str:
    return os.environ["ENVIRONMENT"]


def get_back_end_user() -> str:
    return os.environ["BACK_END_USER"]


def get_back_end_user_pass() -> str:
    return os.environ["BACK_END_USER_PASS"]


def get_mqtt_user() -> str:
    return os.environ["MQTT_USER"]


def get_mqtt_user_pass() -> str:
    return os.environ["MQTT_USER_PASS"]


def get_docker_image() -> str:
    return os.environ["DOCKER_IMAGE"]