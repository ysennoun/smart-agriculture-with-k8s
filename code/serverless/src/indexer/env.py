import os


def get_es_alias():
    return os.environ["ES_ALIAS"]


def get_service_name():
    return os.environ["SERVICE_NAME"]


def get_namespace_name():
    return os.environ["NAMESPACE_NAME"]


def get_mqtt_ca_file():
    return os.environ["MQTT_CA_FILE"]


def get_mqtt_username():
    username_path = os.environ["MQTT_USERNAME_PATH"]
    return open(username_path, 'r').read().rstrip('\n')


def get_mqtt_password():
    password_path = os.environ["MQTT_PASSWORD_PATH"]
    return open(password_path, 'r').read().rstrip('\n')


def get_host(service_name, namespace_name):
    return f"{service_name}.{namespace_name}.svc.cluster.local"


def get_port():
    return int(os.environ["PORT"])


def get_topic_name():
    return os.environ["TOPIC_NAME"]


def get_keep_alive():
    return int(os.getenv("KEEP_ALIVE", 60)) #in seconds