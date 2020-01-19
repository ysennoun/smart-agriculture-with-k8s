import os


def get_service_name():
    return os.environ["SERVICE_NAME"]


def get_namespace_name():
    return os.environ["NAMESPACE_NAME"]


def get_host(service_name, namespace_name):
    return f"{service_name}.{namespace_name}.svc.cluster.local"


def get_port():
    return int(os.environ["PORT"])


def get_topic_name():
    return os.environ["TOPIC_NAME"]


def get_keep_alive():
    return int(os.getenv("KEEP_ALIVE", 60)) #in seconds


def get_brokers_url():
    return os.environ["BROKERS_URL"].split(",")
