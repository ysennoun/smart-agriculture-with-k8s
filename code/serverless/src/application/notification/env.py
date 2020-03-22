import os


def get_threshold_temperature():
    return int(os.environ.get('THRESHOLD_TEMPERATURE', 35))


def get_threshold_humidity():
    return int(os.environ.get('THRESHOLD_HUMIDITY', 10))


def get_threshold_moisture():
    return int(os.environ.get('THRESHOLD_MOISTURE', 30))


def get_smtp_port() -> int:
    return int(os.getenv("SMTP_PORT", "465"))


def get_smtp_server() -> str:
    return os.environ["SMTP_SERVER"]


def get_sender_email() -> str:
    return os.environ["SENDER_EMAIL"]


def get_receiver_email() -> str:
    return os.environ["RECEIVER_EMAIL"]


def get_sender_password() -> str:
    return os.environ["SENDER_PASSWORD"]


def get_message(data: dict) -> str:
    return f"Alert for data: {data}"


def get_port():
    return int(os.environ["PORT"])


def get_service_name():
    return os.environ["SERVICE_NAME"]


def get_namespace_name():
    return os.environ["NAMESPACE_NAME"]


def get_host(service_name, namespace_name):
    return f"{service_name}.{namespace_name}.svc.cluster.local"

def get_topic_name():
    return os.environ["TOPIC_NAME"]


def get_keep_alive():
    return int(os.getenv("KEEP_ALIVE", 60)) #in seconds