import os


def get_port():
    return int(os.environ.get('PORT', 8080))


def get_threshold_temperature():
    return int(os.environ.get('THRESHOLD_TEMPERATURE', 35))


def get_threshold_humidity():
    return int(os.environ.get('THRESHOLD_HUMIDITY', 10))


def get_threshold_moisture():
    return int(os.environ.get('THRESHOLD_MOISTURE', 30))
