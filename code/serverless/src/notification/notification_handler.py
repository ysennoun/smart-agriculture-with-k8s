import json
import smtplib
import ssl
from flask import Response
from notification import env


def is_notification_activated(data: dict):
    temperature = data["temperature"]
    humidity = data["humidity"]
    moisture = data["moisture"]
    if temperature >= env.get_threshold_temperature() or \
            humidity >= env.get_threshold_humidity() or \
            moisture >= env.get_threshold_moisture():
        return True
    else:
        return False


def send_email(data: dict):
    context = ssl.create_default_context()
    with smtplib.SMTP_SSL(env.get_smtp_server(), env.get_smtp_port(), context=context) as server:
        server.login(env.get_sender_email(), env.get_sender_password())
        server.sendmail(env.get_sender_email(), env.get_receiver_email(), env.get_message(data))


def get_status_response(status):
    return Response(
        json.dumps({"status": status}),
        status=200,
        mimetype="application/json"
    )


def handler(data: dict) -> Response:
    if is_notification_activated(data):
        send_email(data)
    return get_status_response("inserted")
