from device import env
import paho.mqtt.client as mqtt
from common.kn_client.kn_broker_client import send_to_broker
from common.utils.logger import Logger

logger = Logger().get_logger()


class MqttClient:

    def handle_on_message(self, payload: str, topic):
        logger.info(f"message {str(payload)} from topic {topic}")
        brokers_url = env.get_brokers_url()
        for broker_url in brokers_url:
            send_to_broker(broker_url, payload)
        logger.info("end xon_message")

    def on_connect(self, client, userdata, flags, rc):
        logger.info(f"Connected with result code {str(rc)}")
        client.subscribe(env.get_topic_name())

    def on_message(self, client, userdata, msg):
        payload = str(msg.payload.decode("utf-8"))
        self.handle_on_message(payload, msg.topic)

    def run(self):
        client = mqtt.Client()
        client.on_connect = self.on_connect
        client.on_message = self.on_message

        service_name = env.get_service_name()
        namespace_name = env.get_namespace_name()
        host = env.get_host(service_name, namespace_name)
        port = env.get_port()
        keep_alive = env.get_keep_alive()
        client.connect(host, port, keep_alive)
        client.loop_forever()
