import os
import smtplib
import ssl
from common.env import get_threshold_temperature
from common.env import get_threshold_humidity
from common.env import get_threshold_moisture
from common.utils.logger import Logger

logger = Logger().get_logger()

PORT = 465  # For SSL
SMTP_SERVER = os.environ["SMTP_SERVER"] #"smtp.gmail.com"
PASSWORD = os.environ["GMAIL_PASSWORD"]
EMAIl_SERVER = os.environ["EMAIl_SERVER"]

DATA_SCHEMA = {
    "type": "object",
    "properties":  {
        "device": {"type": "string"},
        "timestamp": {"type": "number"},
        "temperature": {"type": "number"},
        "humidity": {"type": "number"},
        "moisture": {"type": "number"},
    },
}


def trigger_alert(data):
    logger.info(f"trigger_alert, data: {data}")
    temperature = data["temperature"]
    humidity = data["humidity"]
    moisture = data["moisture"]

    if temperature >= get_threshold_temperature() or \
        humidity <= get_threshold_humidity() or \
        moisture <= get_threshold_moisture():

        logger.info(f"Trigger alert for data: {data}")
        #TODO send alert
        pass


def save(data):
    logger.info(f"Save data: {data}")
    #TODO save data in relational database and object store
    pass


def send_email(receiver_email, message):
    context = ssl.create_default_context()
    with smtplib.SMTP_SSL(SMTP_SERVER, PORT, context=context) as server:
        server.login(EMAIl_SERVER, PASSWORD)
        server.sendmail(EMAIl_SERVER, receiver_email, message)

#https://realpython.com/python-send-email/#sending-a-plain-text-email