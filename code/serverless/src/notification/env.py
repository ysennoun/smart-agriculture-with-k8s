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
