import os


def get_publishing_frequency():
    return int(os.environ.environ['PUBLISHING_FREQUENCY'])  # number of minutes


def get_mqtt_host_ip():
    return os.environ.environ['MQTT_HOST_IP']


def get_mqtt_host_port():
    return int(os.environ.get('MQTT_HOST_PORT', 8883))


def get_mqtt_topic():
    return os.environ["MQTT_TOPIC"]


def get_keep_alive():
    return int(os.getenv("KEEP_ALIVE", 60))  # in seconds


def get_mqtt_client_id():
    username_path = os.environ["MQTT_CLIENT_ID_PATH"]
    return open(username_path, 'r').read().rstrip('\n')


def get_mqtt_ca_file():
    return os.environ["MQTT_CA_FILE"]


def get_mqtt_username():
    username_path = os.environ["MQTT_USERNAME_PATH"]
    return open(username_path, 'r').read().rstrip('\n')


def get_mqtt_password():
    password_path = os.environ["MQTT_PASSWORD_PATH"]
    return open(password_path, 'r').read().rstrip('\n')