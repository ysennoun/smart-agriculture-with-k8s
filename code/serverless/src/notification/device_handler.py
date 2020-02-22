import json
from notification import env
from common.utils.logger import Logger
from notification.notification_handler import notify

logger = Logger().get_logger()


class DeviceHandler:

    def __init__(self, mqtt_client):
        self.mqtt_client = mqtt_client

    def handle_on_message(self, payload: str, topic):
        try:
            logger.info(f"message {str(payload)} from topic {topic}")
            json_payload = json.loads(str(payload))
            notify(json_payload)
        except ValueError as e:
            logger.info(f"ignore message {str(payload)} because not json")
        logger.info("end on_message")

    def on_connect(self, client, userdata, flags, rc):
        logger.info(f"Connected with result code {str(rc)}")
        client.subscribe(env.get_topic_name())

    def on_message(self, client, userdata, msg):
        payload = str(msg.payload.decode("utf-8"))
        self.handle_on_message(payload, msg.topic)

    def run(self):
        self.mqtt_client.on_connect = self.on_connect
        self.mqtt_client.on_message = self.on_message

        service_name = env.get_service_name()
        namespace_name = env.get_namespace_name()
        host = env.get_host(service_name, namespace_name)
        port = env.get_port()
        keep_alive = env.get_keep_alive()
        self.mqtt_client.connect(host, port, keep_alive)
        self.mqtt_client.loop_forever()
