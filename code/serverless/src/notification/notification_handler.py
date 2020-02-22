import smtplib
import ssl
from common.utils.logger import Logger
from notification import env

logger = Logger().get_logger()

def is_notification_activated(data: dict):
    temperature = data["temperature"]
    humidity = data["humidity"]
    moisture = data["moisture"]
    logger.info(temperature)
    logger.info(env.get_threshold_temperature())
    logger.info(humidity)
    logger.info(env.get_threshold_humidity())
    logger.info(moisture)
    logger.info(env.get_threshold_moisture())
    if temperature >= env.get_threshold_temperature() or \
            humidity >= env.get_threshold_humidity() or \
            moisture >= env.get_threshold_moisture():
        logger.info("Notification activated")
        return True
    else:
        logger.info("Notification not activated")
        return False


def send_email(data: dict):
    logger.info("send email attempt")
    context = ssl.create_default_context()
    with smtplib.SMTP_SSL(env.get_smtp_server(), env.get_smtp_port(), context=context) as server:
        logger.info("login try")
        server.login(env.get_sender_email(), env.get_sender_password())
        logger.info("login ok")
        server.sendmail(env.get_sender_email(), env.get_receiver_email(), env.get_message(data))
        logger.info("sent")


def notify(data: dict):
    if is_notification_activated(data):
        send_email(data)